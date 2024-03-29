#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 173;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catdir catfile/;
use AmuseWikiFarm::Archive::BookBuilder;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;
use Path::Tiny;
use File::Copy::Recursive qw/dircopy/;
use File::Path qw/remove_tree make_path/;
use AmuseWikiFarm::Utils::Amuse qw/from_json/;
use JSON::MaybeXS;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site_1 = create_site($schema, '0federation0');
my $bootstrap_1 = 1;

$schema->resultset('Job')->delete;
$schema->resultset('BulkJob')->delete;

$site_1->site_options->update_or_create({ option_name => 'allow_binary_uploads',
                                          option_value => 'flac mp3 ogg' });


my $site_2 = create_site($schema, '0federation2');

SKIP: {
    skip "Site already created", 2 unless $bootstrap_1;
    my $src = catdir(qw/t test-repos 0opds0/);
    my $dest = catdir(repo => $site_1->id);
    remove_tree(catdir($dest, 't'));
    remove_tree(catdir($dest, 'f'));
    dircopy(catdir($src, 't'),
            catdir($dest, 't'));
    dircopy(catdir(qw/t test-repos 0blog0 f/),
            catdir($dest, 'f'));

    path($dest, f => ft => 'f-t-cata.jpg')->copy(path($dest => specials => 'i-x.jpg'));
    my $updir = path($dest, 'uploads');
    $updir->mkpath;
    foreach my $f (path(qw/t binary-files/)->children(qr/\.(flac|ogg|mp3|pdf)$/)) {
        $f->copy("$updir");
    }
    my $attachments = join(' ', map { $_->basename } path($dest, 'uploads')->children);
    path($dest, f => ft => 'f-t-two.muse')->spew_utf8(<<"MUSE");
#ATTACH $attachments
#title test for attachemntes

Test.
MUSE

    $site_1->update_db_from_tree(sub { diag join(' ', @_) });

    is $site_1->titles->count,
      $site_1->titles->search_related('mirror_info')->count, "Mirror info generated for titles";

    is $site_1->attachments->count,
      $site_1->attachments->search_related('mirror_info')->count, "Mirror info generated for attachments";
}

{
    my $dest = catdir(repo => $site_2->id, 'f');
    remove_tree($dest);
    die "dest exists" if -d $dest;
    dircopy(catdir(qw/t test-repos 0blog0 f/), $dest);
    path($dest, ft => 'first-test.muse')->append_utf8("\n\n");
    $site_2->git->add("f");
    $site_2->git->commit({ message => "Add first-test" });
    $site_2->update_db_from_tree(sub { diag join(' ', @_) });
}

foreach my $mi ($schema->resultset('Site')->search({ id => [qw/0federation2 0federation0/] })
                ->search_related('mirror_infos')->all) {
    diag $mi->repo_object->f_full_path_name;
    diag $mi->compute_repo_path;
    diag $mi->repo_object->f_class;
}

# diag Dumper($site_1->titles->mirror_manifest);
is scalar(@{$site_1->titles->mirror_manifest}), $site_1->titles->count +
  $site_1->attachments->search({ f_class => { '!=' => 'special_image' } })->count or
  die Dumper($site_1->titles->mirror_manifest) . ' ' . Dumper([ map { $_->f_full_path_name } $site_1->attachments->all ]) ;

my $just_one = $site_1->titles->search({ 'me.uri' => 'first-test' })->mirror_manifest;
diag Dumper($just_one);

is_deeply([ sort map { $_->{uri} } @$just_one ],
          ['f-t-cata.jpg', 'f-t-testimage.png', 'first-test.muse' ]);

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site_1->canonical);

my $mech_2 = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                 host => $site_2->canonical);


foreach my $m (qw|
                     /manifest.json
                     /category/author/cao/manifest.json
                     /category/author/cao/en/manifest.json
                     /category/topic/ecole/manifest.json
                     /category/topic/ecole/en/manifest.json
                     /library/first-test/manifest.json
                 |) {
    $mech->get_ok($m);
    my $data = from_json($mech->content);
    ok $data->[0]->{f_class};
    ok $data->[0]->{checksum};
    ok $data->[0]->{uri};
    my %sites;
    foreach my $i (@$data) {
        $sites{$i->{site_id}}++;
    }
    is scalar(keys %sites), 1, "No site leaks";
}

# now, create a mirror source for the site2

$site_2->add_to_mirror_origins({
                                remote_domain => $site_1->canonical,
                                remote_path => '/',
                                active => 1,
                               });

{
    my $remote = $site_2->mirror_origins->first;
    ok !$remote->mirror_infos->count;
    _check_bulk_with_jobs($mech, $remote, "Initial load");

    # TODO: check what happens if you try to edit a text with the same uri

    is $site_2->titles->search_related(mirror_info => { mirror_exception  => 'conflict' })->count, 1,
      "Found a conflict for local modified text";
    is $site_2->titles->search_related(mirror_info => { mirror_origin_id  => undef })->count, 1;
    ok $site_2->titles->search_related(mirror_info => { mirror_exception  => '' })->count;
    is $site_2->titles->search_related(mirror_info => { mirror_exception  => 'removed_upstream' })->count, 0;
    ok $remote->mirror_infos->count, "Origins added";
    foreach my $info ($remote->mirror_infos) {
        diag $info->full_uri;
    }

    # nothing changed, bulk job is already completed.
    _check_bulk_without_jobs($mech, $remote, "Nothing changed");


    # add a new file in the src site
    my $test_file = path($site_1->repo_root, f => ft => "for-the-test.muse");
    $test_file->spew_utf8("#title For the test\n#lang en\n\nTest me\n");
    $site_1->update_db_from_tree(sub { diag join(' ', @_) });
    # and check again
    _check_bulk_with_jobs($mech, $remote, "Check after new file in source");

    # modify
    $test_file->append_utf8("test again\n\n");
    $site_1->update_db_from_tree(sub { diag join(' ', @_) });
    _check_bulk_with_jobs($mech, $remote, "Check after modification");


    # modify locally and it will be overwritten
    # 1:1
    _check_bulk_without_jobs($mech, $remote, "Nothing changed after modification");
    # modify
    my $test_file_local = path($site_2->repo_root, f => ft => "for-the-test.muse");
    $test_file_local->spew_utf8("#title XXXX For the test\n#lang en\n\nTestXXX me\n");

    diag "Checking manifest, here they should match, before the registering";
    diag Dumper([ $site_1->titles->search({ 'me.uri' => 'for-the-test' })->mirror_manifest ]);
    diag Dumper([ $site_2->titles->search({ 'me.uri' => 'for-the-test' })->mirror_manifest ]);
    is $site_1->titles->search({ 'me.uri' => 'for-the-test' })->mirror_manifest->[0]->{checksum},
      $site_2->titles->search({ 'me.uri' => 'for-the-test' })->mirror_manifest->[0]->{checksum},
      "Checksums matching";

    # overwrite
    $site_2->update_db_from_tree(sub { diag join(' ', @_) });

    diag "After the update_db_from_tree";
    diag Dumper([ $site_1->titles->search({ 'me.uri' => 'for-the-test' })->mirror_manifest ]);
    diag Dumper([ $site_2->titles->search({ 'me.uri' => 'for-the-test' })->mirror_manifest ]);
    isnt $site_1->titles->search({ 'me.uri' => 'for-the-test' })->mirror_manifest->[0]->{checksum},
      $site_2->titles->search({ 'me.uri' => 'for-the-test' })->mirror_manifest->[0]->{checksum},
      "Checksums differ now";

    _check_bulk_with_jobs($mech, $remote, "Overwritten after local modification");
    diag "After the overwriting";
    diag Dumper([ $site_1->titles->search({ 'me.uri' => 'for-the-test' })->mirror_manifest ]);
    diag Dumper([ $site_2->titles->search({ 'me.uri' => 'for-the-test' })->mirror_manifest ]);
    is $site_1->titles->search({ 'me.uri' => 'for-the-test' })->mirror_manifest->[0]->{checksum},
      $site_2->titles->search({ 'me.uri' => 'for-the-test' })->mirror_manifest->[0]->{checksum},
      "Checksums matching" or die;

    # 1:1
    _check_bulk_without_jobs($mech, $remote, "Check, nothing changed");


    # place a an exception and modify, it's not overwritten and no download is triggered.
    my $test_entry = $site_2->titles->by_full_uri('/library/for-the-test');
    $test_entry->mirror_info->update({ mirror_exception => 'conflict' });
    $test_file_local->spew_utf8("#title XXXX For the test\n#lang en\n\nTestXXX me\n");
    $site_2->update_db_from_tree(sub { diag join(' ', @_) });
    _check_bulk_without_jobs($mech, $remote, "Exception placed, nothing downloaded");

    # remove the exception and it will be fetched again
    $test_entry->mirror_info->update({ mirror_exception => '' });
    _check_bulk_with_jobs($mech, $remote, "Exception removed, download triggered");


    # and removal
    $test_file->remove;
    $site_1->update_db_from_tree(sub { diag join(' ', @_) });
    _check_bulk_without_jobs($mech, $remote, "Check removal");
    is $site_2->titles->search_related(mirror_info => { mirror_exception  => 'removed_upstream' })->count, 1;
    $mech->get("/library/for-the-test");
    is $mech->status, 404;
    $mech_2->get_ok("/library/for-the-test");


    $remote->delete;
    is $site_2->search_related(mirror_infos => { mirror_origin_id  => { '!=' => undef } })->count, 0;
    is $site_2->search_related(mirror_infos => { download_source  => { '!=' => undef } })->count, 0;
    is $site_2->search_related(mirror_infos => { mirror_exception  => 'removed_upstream' })->count, 0;
    is $site_2->search_related(mirror_infos => { mirror_exception  => 'conflict' })->count, 1;
}

diag "Now testing ajax editing";
undef $mech;

{
    my $other_id = $site_1->mirror_infos->first->mirror_info_id;
    $site_2->add_to_mirror_origins({
                                    remote_domain => $site_1->canonical,
                                    remote_path => '/',
                                    active => 1,
                                   });

    $mech_2->get('/federation/mirror-info-edit');
    is $mech_2->status, 401;
    $mech_2->get('/federation/sources');
    is $mech_2->status, 401;
    ok($mech_2->form_id('login-form'), "Found the login-form");
    $mech_2->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root'});
    $mech_2->get_ok('/federation/mirror-info-edit');
    diag $mech_2->content;

    my $target = $site_2->mirror_infos->first;

    foreach my $try ({
                      data => {},
                     },
                     {
                      data => { id => 'xxxx' },
                     },
                     {
                      data => {
                               id => $other_id,
                               field => 'mirror_exception',
                               value => 'cross-site post',
                              },
                     },
                     {
                      data => {
                               id => $target->mirror_info_id,
                               field => 'pippo',
                              },
                     },
                     {
                      data => {
                               id => $target->mirror_info_id,
                               field => 'mirror_exception',
                               value => 'local',
                              },
                      ok => 1,
                     },
                     {
                      data => {
                               id => $target->mirror_info_id,
                               field => 'mirror_exception',
                               value => '',
                              },
                      ok => 1,
                     },
                     {
                      data => {
                               id => $target->mirror_info_id,
                               field => 'mirror_origin_id',
                               value => 'local',
                              },
                     },
                     {
                      data => {
                               id => $target->mirror_info_id,
                               field => 'mirror_origin_id',
                               value => 99999,
                              },
                     },
                     {
                      data => {
                               id => $target->mirror_info_id,
                               field => 'mirror_origin_id',
                               value => $site_2->mirror_origins->first->mirror_origin_id,
                              },
                      ok => 1,
                     },
                     {
                      data => {
                               id => $target->mirror_info_id,
                               field => 'mirror_origin_id',
                               value => '',
                              },
                      ok => 1,
                     }
                    ) {
        diag Dumper($try->{data});
        # $target->update({ last_updated => DateTime->now });
        # sleep 1;
        $mech_2->post('/federation/mirror-info-edit', $try->{data});
        # sleep 1;
        # $target->update({ last_updated => DateTime->now });
        my $data = decode_json($mech_2->content);
        diag Dumper($data);
        if ($try->{ok}) {
            ok $data->{ok}, "Response to " . encode_json($try->{data}) . " is fine";
        }
        else {
            ok $data->{error}, "Response to " . encode_json($try->{data}) . " is error";
        }
    }
}


sub _check_bulk_without_jobs {
    my ($mech, $remote, $msg) = @_;
    sleep 1;
    $remote->ua($mech);
    my $res = $remote->fetch_remote;
    # diag Dumper($res);
    my $bulk_job = $remote->prepare_download($res->{data});
    is $bulk_job->discard_changes->status, 'completed', $msg or die Dumper([ $res->{data},
                                                                             $bulk_job->expected_documents ]);
    ok !$bulk_job->produced, "Nothing produced for $msg";
}

sub _check_bulk_with_jobs {
    my ($mech, $remote, $msg) = @_;
    sleep 1;
    $remote->ua($mech);
    my $res = $remote->fetch_remote;
    diag Dumper($res);
    ok $res->{data}, "data for $msg";
    ok !$res->{error}, "no error for $msg";
    my $bulk_job = $remote->prepare_download($res->{data});
    is $bulk_job->discard_changes->status, 'active', $msg;
    while (my $job = $site_2->jobs->dequeue) {
        diag "Job is " . $job->task;
        $job->dispatch_job({ ua => $mech });
        is $job->status, 'completed';
        diag $job->logs;
        diag "Produced: " . ($job->produced || "nothing");
        diag "Parent is " . ($job->bulk_job_id || "none");
    }
    is $bulk_job->discard_changes->status, 'completed', $msg;
    diag $bulk_job->produced;
    ok $bulk_job->produced, $msg;
}

# foreach my $obj ($site_1->titles->all, $site_1->attachments->all) {
#     $mech->get_ok($obj->full_uri);
# }

__END__

        f/ft/f-t-cata.jpg
        f/ft/f-t-testimage.png


* Origin:

 - store checksums for indexed files
 - provide manifest.json with URLs and checksums to various access points
   like /listing /category/x/y/manifest.json

* Client:

 - has a list of URLs to mirror.
 - retrieves the manifest
 - exclude exceptions
 - checks the netto list. Use a timestamp as reference
    - already mirrored? compare the checksums. 
       - If different? Fetch the resource.
       - Update the mirroring timestamp

    - new file? Fetch the resource and add the mirroring info,
      including the mirroring timestamp.

    - check files having that resource as origin and a timestamp which
      is not the same. Remove them.

* Interface:

 - you can add one or more origins
 - each origin can have exceptions
 - when adding exceptions, define a behavior. Remove files? Unlink
   them?
 - when removing origins, define a behavior. Remove files? Unlink
   them?


* Schema

Each site can have one or more mirror_origin. It defines a domain and
a path where to fetch the manifests.

Each text and attachment has a mirror_info record attached. With
mirror_origin_id null, it's a regular, local file. It still carries
the md5sum. We point to this record for exclusions and conflicts.

mirror_exclusion can be "exclusion" or "conflict".




