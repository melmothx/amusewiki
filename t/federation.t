#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 107;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catdir catfile/;
use AmuseWikiFarm::Archive::BookBuilder;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site run_all_jobs/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;
use Path::Tiny;
use File::Copy::Recursive qw/dircopy/;
use File::Path qw/remove_tree make_path/;
use AmuseWikiFarm::Utils::Amuse qw/from_json/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my ($bootstrap_1, $site_1);

# remove when devel is done.
unless (1 and $site_1 = $schema->resultset('Site')->find('0federation0')) {
    $site_1 = create_site($schema, '0federation0');
    $bootstrap_1 = 1;
}

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
    $site_2->update_db_from_tree(sub { diag join(' ', @_) });

}

foreach my $mi ($schema->resultset('MirrorInfo')->all) {
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
    $remote->ua($mech);
    my $res = $remote->fetch_remote;
    ok $res->{data};
    ok !$res->{error};
    diag Dumper($res);
    my $bulk_job = $remote->prepare_download($res->{data});

    is $bulk_job->status, 'active';

    # TODO: check what happens if you try to edit a text with the same uri

    is $site_2->titles->search_related(mirror_info => { mirror_exception  => 'conflict' })->count, 1;
    is $site_2->titles->search_related(mirror_info => { mirror_origin_id  => undef })->count, 1;
    ok $site_2->titles->search_related(mirror_info => { mirror_exception  => '' })->count;
    is $site_2->titles->search_related(mirror_info => { mirror_exception  => 'removed_upstream' })->count, 0;
    ok $remote->mirror_infos->count, "Origins added";
    foreach my $info ($remote->mirror_infos) {
        diag $info->full_uri;
    }
    # mirror doesn't work.
    # $mech->mirror('https://0federation0.amusewiki.org/library/title-entry-21.muse', "var/cache/test.muse");
    while (my $job = $site_2->jobs->dequeue) {
        $job->dispatch_job({ ua => $mech });
        is $job->status, 'completed';
        diag $job->logs;
    }
    is $bulk_job->discard_changes->status, 'completed';
}


foreach my $obj ($site_1->titles->all, $site_1->attachments->all) {
    $mech->get_ok($obj->full_uri);
}

__END__


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




