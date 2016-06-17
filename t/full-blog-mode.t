#!perl

use strict;
use warnings;

use utf8;
use Test::More tests => 7;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Text::Amuse::Compile::Utils qw/write_file/;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0fancy0');

my ($revision) = $site
  ->create_new_text({
                     title => 'My new blog post!',
                     uri => 'my-test',
                     lang => 'en',
                     textbody => '<p>hello there</p>',
                     teaser => '<p>this</p><p>is =the= <em>teaser</em></p>',
                     notes => '<b>notes</b>',
                    }, 'text');
my $body = $revision->muse_body;
like $body, qr{\#notes <strong>notes</strong>}, "Found the notes";
like $body, qr{\#teaser this is =the= <em>teaser</em>}, "Found the teaser";
$revision->add_attachment(catfile(qw/t files shot.png/));

my @files = @{$revision->attached_files};
my $attached = $files[0];
ok ($attached, "Attached file $attached");
$body = "#cover $attached\n#coverwidth 0.5\n" . $body;
$revision->edit($body);
$revision->commit_version;
$revision->publish_text;
my $text = $site->titles->first;
is $text->uri, 'my-test', "Found the text";
is $text->cover, $attached, "Cover found ($attached)";
is $text->teaser, "this is <code>the</code> <em>teaser</em>", "Found the teaser";

$body =~ s!^\#cover .*$!#cover <script>hello()</script>!m;
my $rev = $text->new_revision;
$rev->edit($body);
$rev->commit_version;
$rev->publish_text;
diag $rev->muse_body;
$text->discard_changes;
is $text->cover, '', "cover field nuked with garbage";
