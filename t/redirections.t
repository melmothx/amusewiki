#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 9;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Slurp qw/write_file read_file/;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use File::Path qw/make_path/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site_id =  '0rdrct0';
my $site = create_site($schema, $site_id);

# create a redirectio

my $repo_root = $site->repo_root;

my $text_path = catdir($repo_root, qw/a at/);

unless (-d $text_path) {
    make_path($text_path) or die $!;
}

my $count = 0;
foreach my $redir ('Redirect:', 'rediReCt', 'REDIRECT:') {
    my $textc = <<"MUSE";
#title a test $count
#DELETED $redir a-test-pippo

Deleted
MUSE
    my $text = catfile($text_path, "a-test-$count.muse");
    write_file($text, { binmode => ':encoding(utf-8)'}, $textc);
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

Good

MUSE

write_file (catfile($repo_root, qw/a at a-test-pippo.muse/),
            { binmode => ':encoding(utf-8)' },
            $good);

$site->update_db_from_tree;

my $published = $site->titles->published_texts->first;

ok($published, "Found the published text");

like $published->html_body, qr/Good/;



