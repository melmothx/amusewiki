use strict;
use warnings;
use Test::More tests => 133;
use File::Spec;
use Data::Dumper;
use File::Spec::Functions qw/catfile/;
use Cwd;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = $schema->resultset('Site')->find('0blog0');
$site->update({ bb_page_limit => 5 });
# fake it for test purpose
$site->titles->update({ text_size => 1900 });

use Test::WWW::Mechanize::Catalyst;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');


$mech->get_ok('/?__language=en');
# set it to english for testing purposes.
$mech->get('/bookbuilder');
is $mech->status, 401;


$mech->get('/bookbuilder/add/alsdflasdf');
is $mech->status, 401;

$mech->content_contains("test if the user is a human");

$mech->submit_form(with_fields => { __auth_human => 'January' });
is ($mech->status, '404', "bogus text not found: " . $mech->status);
is $mech->uri->path, '/library/alsdflasdf';
$mech->content_contains("Couldn't add the text");
$mech->content_contains("Page not found!");


$mech->get('/bookbuilder/add/alsdflasdf');

is ($mech->status, '404', "bogus text not found: " . $mech->status);
$mech->content_contains("Couldn't add the text");
$mech->content_contains("Page not found!");

$mech->get_ok('/bookbuilder/fonts');
{
    my @links = grep { $_->url =~ m/font-preview/ } $mech->find_all_links;
    ok (scalar @links, "Found font-preview links");
}

$mech->get_ok('/bookbuilder/add/first-test');
is $mech->uri->path, '/library/first-test';
$mech->get_ok('/bookbuilder');
$mech->get_ok('/bookbuilder');
$mech->content_contains('/library/first-test');
$mech->submit_form(form_id => 'bookbuilder-edit-list-1',
                   button => 'delete');
$mech->content_lacks('/library/first-test');
$mech->get_ok('/bookbuilder');
$mech->content_lacks('/library/first-test');

$mech->get_ok('/library/second-test');


# 5 times
foreach my $i (1..5) {
    $mech->get_ok('/bookbuilder/add/second-test');
    is ($mech->uri->path, '/library/second-test');
    $mech->content_contains('The text was added to the bookbuilder');
    $mech->get('/bookbuilder');
    $mech->content_lacks("Couldn't add the text");
    $mech->content_lacks("Quota exceeded");
    $mech->content_like(qr/Total pages: \Q$i\E/) or die $mech->content;
}

$mech->get_ok('/bookbuilder/add/second-test');
$mech->content_contains("Quota exceeded, too many pages");
$mech->get_ok('/bookbuilder');
$mech->content_contains('second-test');
$mech->get_ok('/bookbuilder/add/first-test');
$mech->content_contains("Quota exceeded");
$mech->get_ok('/bookbuilder');
$mech->content_lacks('first-test');
$mech->content_contains("Total pages: 5") or diag $mech->content;

$mech->get('/bookbuilder/cover');
is ($mech->status, '404');
$mech->get('/bookbuilder');

my @purge;
foreach my $cover (qw/shot.jpg shot.png/) {
    $mech->get_ok('/bookbuilder');
    my $coverfile = File::Spec->catfile(qw/t files/, $cover);
    my $res = $mech->submit_form(with_fields => {
                                                 coverimage => $coverfile,
                                                },
                                 button => 'update',
                                );
    for (1..2) {
        $mech->get_ok('/bookbuilder/cover');
        $mech->get_ok('/bookbuilder');
        $mech->submit_form(with_fields => { title => $cover },
                           button => 'build');
        if ($mech->uri->path =~ m{tasks/status/([0-9]+)}) {
            my $jid = $1;
            my $job = $site->jobs->find($jid);
            ok ($job, "Found the job $jid");
            $job->dispatch_job;
            ok ($job->produced);
            ok ($job->job_files->search({ slot => 'cover' })->count,
                "Found the cover");
            diag Dumper([$job->produced_files]);
            push @purge, $job;
        }
        else {
            die "No task path . " . $mech->uri->path ;
        }
    }
}


$mech->get_ok('/bookbuilder');
$mech->submit_form(with_fields => {
                                   removecover => 1,
                                  },
                   button => 'build',
                  );
if ($mech->uri->path =~ m{tasks/status/([0-9]+)}) {
    my $jid = $1;
    my $job = $site->jobs->find($jid);
    ok ($job, "Found the job $jid");
    $job->dispatch_job;
    ok ($job->produced);
    push @purge, $job;
}
else {
    die "No task path . " . $mech->uri->path ;
}

$mech->get('/bookbuilder/cover');
is $mech->status, '404', "Cover not found with removecover";


$mech->get('/bookbuilder');
$mech->content_lacks('HASH(');

foreach my $fmt (qw/pdf epub/) {
    $mech->get_ok('/bookbuilder/add/first-test');
    $mech->get('/bookbuilder');
    $mech->form_id('bbform');
    $mech->field(format => $fmt);
    $mech->click('update');
    $mech->submit_form(form_id => 'bb-clear-all-form',
                       button => "clear");
    $mech->get_ok('/bookbuilder/add/first-test');
    $mech->get('/bookbuilder');
    $mech->content_like(qr{value="\Q$fmt\E"\s+checked="checked"},
                       "Settings are the same ($fmt)");

    $mech->submit_form(form_id => 'bb-clear-all-form',
                       button => "reset");
    $mech->content_contains('bb-instructions-1.png') or diag $mech->content;

    $mech->get_ok('/bookbuilder/add/first-test');
    $mech->get('/bookbuilder');
    $mech->content_like(qr{value="pdf"\s+checked="checked"},
                       "Settings are back to factory");
    $mech->submit_form(form_id => 'bb-clear-all-form',
                       button => "reset");
    $mech->content_contains('bb-instructions-1.png') or diag $mech->content;

}





$mech->get('/library/first-test');

ok($mech->follow_link(url_regex => qr{/library/first-test/bbselect}));

is $mech->uri->path, '/library/first-test/bbselect';

ok($mech->form_id("book-builder-add-text-partial"), "Found form for partials");

my @inputs = $mech->grep_inputs({ type => qr{^checkbox$},
                                  name => qr{^select$} });
is (scalar(@inputs), 14, "Found 14 checkboxes");

# pre and post should already be selected
$mech->tick(select => '0');
$mech->click;
is $mech->uri->path, '/library/first-test', "Back to the text";
$mech->get_ok('/bookbuilder');
# check the link
$mech->content_contains('first-test/bbselect?selected=pre-0-post"');

$mech->get_ok('/library/second-test');
ok($mech->follow_link(url_regex => qr{/library/second-test/bbselect}));
ok($mech->form_id("book-builder-add-text-partial"), "Found form for partials");
@inputs = $mech->grep_inputs({ type => qr{^checkbox$},
                               name => qr{^select$} });
is (scalar(@inputs), 3, "Found 3 checkbox");
$mech->tick(select => '1');
$mech->click;
$mech->get_ok('/bookbuilder');
$mech->content_contains('second-test/bbselect?selected=pre-1"');

$mech->get_ok('/library/do-this-by-yourself');
ok($mech->follow_link(url_regex => qr{/bookbuilder/add/do-this-by-yourself}));
$mech->get_ok('/bookbuilder');
$mech->content_contains('/library/do-this-by-yourself');
$mech->content_lacks('do-this-by-yourself/bbselect');

$mech->submit_form(with_fields => {
                                   title => 'x',
                                   coverimage => File::Spec->catfile(qw/t files
                                                                        shot.png/),
                                  },
                   button => 'build');

if ($mech->uri->path =~ m{tasks/status/([0-9]+)}) {
    my $job = $site->jobs->find($1);
    ok ($job, "Found the job");
    # diag Dumper($job->job_data);
    # this is all we need for the compiler to work
    is_deeply($job->job_data->{textlist}, [
                                           'first-test:pre,0,post',
                                           'second-test:pre,1',
                                           'do-this-by-yourself',
                                          ], "List is ok");
    $job->dispatch_job;
    ok ($job->job_files->search({ slot => 'cover' })->count, "Found the cover"),
    push @purge, $job;
}
else {
    die $mech->uri->path . "is not a tasks url one";
}

foreach my $purgef (@purge) {
    diag "Purging " . $purgef->id . ' ' . join (' ', $purgef->produced_files);
    $purgef->delete;
}

# new instance
$mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');
$mech->get_ok('/?__language=en');
$site->update({ bb_page_limit => 2 });
$mech->get_ok('/library/first-test');

foreach my $title ($site->titles) {
    $title->text_html_structure(1);
}

$mech->get('/bookbuilder/add/first-test');
is $mech->status, 401;
$mech->submit_form(with_fields => { __auth_human => 'January' });
$mech->content_contains("Quota exceeded",  "Quota hit adding the whole text");

ok($mech->follow_link(url_regex => qr{/library/first-test/bbselect}));
ok($mech->form_id("book-builder-add-text-partial"), "Found form for partials");
$mech->tick(select => '1');
$mech->click;
$mech->get_ok('/bookbuilder');
$mech->content_lacks("Quota exceeded");
$mech->content_contains('first-test/bbselect?selected=pre-1-post"');

# restore
$site->update({ bb_page_limit => 10 });


