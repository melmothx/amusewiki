#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 60;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Text::Amuse::Compile::Utils qw/write_file read_file/;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use File::Path qw/make_path/;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site_id =  '0rdrct0';
my $site = create_site($schema, $site_id);

# create a redirectio

my $repo_root = $site->repo_root;

my $text_path = catdir($repo_root, qw/a at/);

unless (-d $text_path) {
    make_path($text_path) or die $!;
}

my @text_aliases;
my $count = 0;
foreach my $redir ('Redirect:', 'rediReCt', 'REDIRECT:') {
    my $textc = <<"MUSE";
#title a test $count
#DELETED $redir a-test-pippo

Deleted
MUSE
    my $text = "a-test-" . $count;
    push @text_aliases, $text;
    write_file(catfile($text_path, "$text.muse"),
               $textc);
    $count++;
}
$site->update_db_from_tree;


my @aliases = $site->redirections;
ok (@aliases == $count, "Found $count aliases");
my $alias = $site->redirections->search({ uri => 'a-test-0' })->single;
ok ($alias);

is ($alias->uri, 'a-test-0', "uri ok");
is ($alias->type, 'text', "type ok");
is ($alias->redirect, 'a-test-pippo', "redirection ok");
is ($alias->site_id, $site_id, "site_id ok");

my @texts = $site->titles->published_texts;

ok( !@texts, "No published texts so far");

my $good = <<'MUSE';
#title a test $count
#SORTauthors PLUTO, pluto, pluto-2, pluto-3
#SORTtopics TOPIC-1, topic-1, topic-2, topic-3

Good

MUSE

write_file (catfile($repo_root, qw/a at a-test-pippo.muse/),
            $good);

$site->update_db_from_tree;

my $published = $site->titles->published_texts->first;

ok($published, "Found the published text");

like $published->html_body, qr/Good/;

my @cats = $published->categories;

is(scalar(@cats), 6, "Found 6 categories");


# define aliases

my @author_aliases = (qw/pluto-2 pluto-3/);
my @topic_aliases = (qw/topic-2 topic-3/);

foreach my $uri (@author_aliases) {
    $site->redirections->update_or_create({
                                           uri => $uri,
                                           type => 'author',
                                           redirect => 'pluto',
                                          });
}
foreach my $uri (@topic_aliases) {
    $site->redirections->update_or_create({
                                           uri => $uri,
                                           type => 'topic',
                                           redirect => 'topic-1',
                                          });
}

# reindex

$site->compile_and_index_files([catfile($repo_root, qw/a at a-test-pippo.muse/)]);

$published->discard_changes;

@cats = $published->categories->search({ text_count => { '>' => 0 } });

# foreach my $c (@cats) {
#     print "Found ", $c->uri, "\n";
# }

is(scalar(@cats), 2, "Found 2 categories");

my ($author) = $published->authors;
my ($topic)  = $published->topics;

is ($topic->uri, 'topic-1');
is ($author->uri, 'pluto');


my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");

$mech->get_ok('/');
$mech->get_ok('/library');
$mech->content_contains('Full list of texts');
$mech->content_contains('/library/a-test-pippo');
ok($mech->follow_link( text_regex => qr/a test/ ));

my $uri = $mech->uri->path;

diag "Text is $uri";

foreach my $alias (@text_aliases) {
    $mech->get_ok("/library/$alias");
    is $mech->uri->path, $uri, "/library/$alias points to $uri";
    $mech->get_ok("/$alias");
    is $mech->uri->path, $uri, "/$alias points to $uri";
}


$uri = "/category/topic/topic-1";

foreach my $alias (@topic_aliases) {
    $mech->get_ok("/category/topic/$alias");
    is $mech->uri->path, $uri, "/category/topic/$alias points to $uri";
    $mech->get_ok("/$alias");
    is $mech->uri->path, $uri, "/$alias points to $uri";
}

$uri = "/category/author/pluto";

foreach my $alias (@author_aliases) {
    $mech->get_ok("/category/author/$alias");
    is $mech->uri->path, $uri, "/category/author/$alias points to $uri";
    $mech->get_ok("/$alias");
    is $mech->uri->path, $uri, "/$alias points to $uri";
}

$alias = $site->redirections->find({ uri => 'pluto-2', type => 'author' });

my @linked = $alias->linked_texts;
is (scalar(@linked), 1, "Found one text");
ok ($alias->can_safe_delete, "Alias can be deleted safely");

$site->add_to_legacy_links({ legacy_path => 'bla/bla/200', new_path => 'library' });
$site->add_to_legacy_links({ legacy_path => 'bla/bla/xxx', new_path => 'search' });
$site->add_to_legacy_links({ legacy_path => 'bla/bla/undef', new_path => '' });
for my $trailing ('', '/') {
    $mech->get_ok('/bla/bla/200' . $trailing);
    is $mech->uri->path, '/library';
    $mech->get_ok('/bla/bla/xxx' . $trailing);
    is $mech->uri->path, '/search';
    $mech->get_ok('/bla/bla/undef' . $trailing);
    is $mech->uri->path, '/latest';
}


