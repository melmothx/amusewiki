#!perl

use strict;
use warnings;

use utf8;
use Test::More tests => 33;
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
$site->update({
               secure_site => 0,
               blog_style => 1,
               sitename => "My new blog",
              });

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

my $orig_body = $body;
$body =~ s!^\#cover .*$!#cover <script>hello()</script>!m;
my $rev = $text->new_revision;
$rev->edit($body);
$rev->commit_version;
$rev->publish_text;
diag $rev->muse_body;
$site->update({
               pdf => 1,
               epub => 1,
              });

$text->discard_changes;
is $text->cover, '', "cover field nuked with garbage";



$rev = $text->new_revision;
$rev->edit($orig_body);
$rev->commit_version;
$rev->publish_text;
diag $rev->muse_body;
$text->discard_changes;
is $text->cover, $attached, "cover field restored";

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/');
is $mech->uri->path, '/latest', "Redirected to /latest";
$mech->content_lacks('Authors');
$mech->content_lacks('Topics');

$site->update({
               pdf => 0,
              });


add_text({
          title => 'A second entry',
          teaser => '<p> This is going to be a long <b>trip</b>',
          author => 'Pippo',
          lang => 'en',
          textbody => '<p>hello there</p>',
          teaser => '<p>this</p><p>is =another= <em>teaser</em></p>',
         });
$mech->get_ok('/');
$mech->content_lacks('Topics');
$mech->content_like(qr/Authors.*Authors/s);

add_text({
          title => 'A third entry',
          teaser => '<p> This is going to be a long <b>trip</b>',
          author => 'Pippo',
          subtitle => 'With a subtitle',
          lang => 'en',
          textbody => '<p>hello there</p>',
          teaser => '<p>this</p><p>is =another= <em>teaser</em></p>',
          SORTtopics => 'blabla',
         });
$mech->get_ok('/');
$mech->content_like(qr/Topics.*Topics/s);
$mech->content_like(qr/Authors.*Authors/s);

$mech->content_lacks('class="pagination"');

foreach my $num (1..10) {
    add_text({
              title => "Another one... $num",
              teaser => ("This buffer is for notes you don't want to save, and
for Lisp evaluation. If you want to create a file, visit that file
with C-x C-f, then enter the text in that file's own buffer. " x $num ),
              lang => 'en',
              subtitle => ("Sub " x $num),
              textbody => "Nothing interesting",
             });
}

$mech->get_ok('/latest');
$mech->content_contains('class="pagination"');
$mech->content_contains('/latest/2');

$mech->get_ok('/latest/2');
$mech->content_contains('A second entry');

$site->update({
               pdf => 1,
              });

$mech->content_contains('amw-main-layout-column');
$mech->content_lacks('amw-left-sidebar-column');
$mech->content_lacks('amw-right-sidebar-column');

$site->add_to_site_options({ option_name => 'left_sidebar_html',
                             option_value => '<strong>Left bar</strong>',
                           });

$mech->get_ok('/');
$mech->content_contains('amw-left-sidebar-column');
$mech->content_contains('<strong>Left bar</strong>');

$site->add_to_site_options({ option_name => 'right_sidebar_html',
                             option_value => '<strong>Right bar</strong>',
                           });


$mech->get_ok('/');
$mech->content_contains('amw-right-sidebar-column');
$mech->content_contains('<strong>Right bar</strong>');




sub add_text {
    my $args = shift;
    my ($rev) = $site->create_new_text($args, 'text');
    my $body = $rev->muse_body;
    $rev->add_attachment(catfile(qw/t files shot.png/));
    my @files = @{$rev->attached_files};
    my $attached = $files[0];
    $body = "#cover $attached\n#coverwidth 0.5\n" . $body;
    $rev->edit($body);
    $rev->commit_version;
    $rev->publish_text;
}
