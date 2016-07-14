#!perl

use strict;
use warnings;

use utf8;
use Test::More tests => 188;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Text::Amuse::Compile::Utils qw/write_file/;
use Data::Dumper;
use File::Copy (qw/copy/);

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0fancy0');
$site->update({
               secure_site => 0,
               blog_style => 1,
               sitename => "My new blog",
               multilanguage => 'en it hr de',
              });

$site->site_options->create({ option_name => 'text_infobox_at_the_bottom',
                              option_value => 1 });

my ($revision) = $site
  ->create_new_text({
                     title => 'My new blog post!',
                     uri => 'my-test',
                     lang => 'en',
                     textbody => '<h3>1</h3><p>hello there</p><h3>2</h3><h3>3</h3>',
                     teaser => '<p>this</p><p>is =the= <em>teaser</em></p>',
                     notes => '<b>notes</b>',
                    }, 'text');
my $body = $revision->muse_body;
like $body, qr{\#notes <strong>notes</strong>}, "Found the notes";
like $body, qr{\#teaser this is =the= <em>teaser</em>}, "Found the teaser";


my $attached = $revision->add_attachment(catfile(qw/t files shot.png/))->{attachment};
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
is $rev->document_html_headers->{cover}, 'file_not_found.png';
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
is $rev->document_html_headers->{cover}, $attached;
$rev->publish_text;
diag $rev->muse_body;
$text->discard_changes;
is $text->cover, $attached, "cover field restored";

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               agent => 'Mozilla/5.0 (X11; Linux x86_64; rv:38.0) Gecko/20100101 Firefox/38.0 Iceweasel/38.8.0',
                                               host => $site->canonical);

$mech->get_ok('/opds/new');
$mech->content_contains($text->cover_uri);
$mech->content_contains($text->cover_thumbnail_uri);
$mech->get_ok($text->cover_uri);
$mech->get_ok($text->cover_thumbnail_uri);

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
          pubdate => "2013-01-01",
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

{
    my $new_uri = add_text({
                            title => 'About',
                            teaser => 'ABOUT TEASER',
                            author => 'Pippo',
                            lang => 'en',
                            textbody => '<p>hello there about body</p>',
                           }, 'special');
    $mech->get_ok('/feed');
    $mech->content_contains("ABOUT TEASER");
    $mech->content_lacks("hello there about body");
    $mech->get_ok('/');
    $mech->get_ok($new_uri);
    $mech->content_contains('<meta name="description" content="ABOUT TEASER"');
    $mech->content_lacks('chevron');
}

foreach my $num (1..10) {
    my $new_uri = add_text({
              title => "Another one... $num",
              teaser => ("Teaser $num. This buffer is for notes you don't want to save, and
for Lisp evaluation. If you want to create a file, visit that file
with C-x C-f, then enter the text in that file's own buffer. " x $num ),
              lang => 'en',
              subtitle => ("Sub " x $num),
              textbody => "Nothing interesting",
              SORTtopics => "first topic, second topic",
              pubdate => DateTime->new(year => 2015, month => $num)->iso8601,
             });
    $mech->get_ok('/feed');
    $mech->content_contains("Teaser $num.");
    $mech->get_ok($new_uri);
    $mech->content_contains('chevron');
    $mech->content_contains(qq{<meta name="description" content="Teaser $num.});
}

{
    my $new_uri = add_text({
                            title => 'No teaser, no cover',
                            author => 'Pippo',
                            lang => 'en',
                            date => '1940',
                            textbody => '<p>hello there</p>',
                            pubdate => "2011-01-01 14:00",
                            notes => 'Some *notes*',
                           }, text => 1);
    $mech->get_ok($new_uri);
    $mech->content_contains(qq{<meta name="description" content="Pippo No teaser, no cover 1940 Some notes"});
}

add_text({
          title => 'Baf!',
          author => 'Pippo',
          lang => 'en',
          textbody => '<p>hello there</p>',
          pubdate => "2011-01-01 14:00",
         }, text => 1);


$mech->get_ok('/');


$mech->get_ok('/latest');
$mech->content_contains('class="pagination"');
$mech->content_contains('/latest/2');

$mech->get_ok('/latest/2');
$mech->content_contains('A second entry');

# check the pagination
{
    foreach my $text ($site->titles->published_texts->all) {
        $mech->post('/stats/register' => {
                                          id => $text->id,
                                          type => "download",
                                         });
    }
    sleep 1;
    $mech->get('/stats/popular');
    $mech->content_contains('class="pagination"');
    $mech->content_contains('/stats/popular/2');

    my $opt = $site->site_options->find_or_create({ option_name => 'pagination_size' });
    $opt->update({ option_value => 25 });

    $mech->get_ok('/latest');
    $mech->content_lacks('class="pagination"');
    $mech->content_lacks('/latest/2');


    $mech->get_ok('/stats/popular');
    $mech->content_lacks('class="pagination"');
    $mech->content_lacks('/stats/popular/2');

    $opt->update({ option_value => 1 });

    $mech->get_ok('/category/author/pippo');
    $mech->content_contains('class="pagination"');
    $mech->content_contains('/category/author/pippo?page=2');

    $mech->get_ok('/monthly/2011/1');
    $mech->content_contains('class="pagination"');
    $mech->content_contains('/monthly/2011/1?page=2');

    $opt->update({ option_value => 10 });

    $mech->get_ok('/category/author/pippo');
    $mech->content_lacks('class="pagination"');
    $mech->content_lacks('/category/author/pippo?page=2');

    $mech->get_ok('/monthly/2011/1');
    $mech->content_lacks('class="pagination"');
    $mech->content_lacks('/monthly/2011/1?page=2');
}

$site->update({
               pdf => 1,
              });
$mech->get_ok('/');
$mech->content_contains('amw-main-layout-column');

my %snippets = (
                bottom => '<div id="amw-cloud-embedded-sidebar"></div>
<script type="text/javascript">
$(document).ready(function() {
    $("#amw-cloud-embedded-sidebar").load("/cloud?limit=0&bare=1");
});
</script>
',
                right => '<div id="amw-cloud-embedded-authors"></div>
<script type="text/javascript">
$(document).ready(function() {
    $("#amw-cloud-embedded-authors").load("/cloud/authors?bare=1&max=10");
});
</script>
',
                top => '<div id="amw-cloud-embedded-topics"></div>
<script type="text/javascript">
$(document).ready(function() {
    $("#amw-cloud-embedded-topics").load("/cloud/topics?bare=1&max=10");
});
</script>
',
                left => '<div id="amw-monthly-embedded-sidebar"></div>
<script type="text/javascript">
$(document).ready(function() {
    $("#amw-monthly-embedded-sidebar").load("/monthly?bare=1");
});
</script>
',
               );

foreach my $element (qw/left right top bottom/) {
    my $html = '<strong>Layout element' . uc($element) . '</strong>' . $snippets{$element};
    $mech->content_lacks($html);
    $site->add_to_site_options({ option_name => "${element}_layout_html",
                                 option_value => $html });
    $mech->get_ok('/');
    $mech->content_contains($html);
}

diag "Testing tag cloud";

my $guard = $schema->txn_scope_guard;
foreach my $num (1..100) {
    foreach my $type (qw/topic author/) {
        $site->add_to_categories({
                                  name => "test $type $num",
                                  uri => "test-$type-$num",
                                  type => $type,
                                  text_count => $num,
                                  sorting_pos => $num,
                                 })
    }
}
$guard->commit;

$mech->get_ok('/cloud');
$mech->content_contains('>test topic 1<');
$mech->content_contains('>test topic 100<');
$mech->content_contains('>test author 1<');
$mech->content_contains('>test author 100<');
my @links = grep { $_->url =~ m/\/category\// } $mech->find_all_links;
$mech->links_ok(\@links);
ok(scalar(@links), "Found and tested " . scalar(@links) . " links");

$mech->get_ok('/cloud?limit=60');
$mech->content_lacks('>test topic 1<');
$mech->content_lacks('>test topic 59<');
$mech->content_contains('>test topic 60<');
$mech->content_contains('>test topic 100<');
$mech->content_lacks('>test author 1<');
$mech->content_lacks('>test author 59<');
$mech->content_contains('>test author 61<');
$mech->content_contains('>test author 100<');

$mech->get_ok('/cloud?limit=60&bare=1');
$mech->content_lacks('>test topic 1<');
$mech->content_lacks('>test topic 59<');
$mech->content_contains('>test topic 60<');
$mech->content_contains('>test topic 100<');
$mech->content_lacks('>test author 1<');
$mech->content_lacks('>test author 59<');
$mech->content_contains('>test author 60<');
$mech->content_contains('>test author 100<');
$mech->content_lacks('My new blog');

$mech->get_ok('/cloud/authors');
$mech->content_contains('>test author 55<');
$mech->content_lacks('>test topic 55<');
$mech->get_ok('/cloud/topics');
$mech->content_contains('>test topic 55<');
$mech->content_lacks('>test author 55<');

copy(catfile(qw/t files widebanner.png/),
     catfile($site->path_for_site_files));
$mech->get_ok('/');
$mech->content_contains('widebanner.png');

my $deleted_text;
for my $month (1,2) {
    $mech->get_ok('/monthly');
    $mech->content_contains("monthly-list-item-2015-$month");
    my $archive = $site->monthly_archives->find({ year => 2015, month => $month });
    ok($archive, "Found month");
    foreach my $text ($archive->titles) {
        ok($text, "Updating text setting the deletion");
        my $rev = $text->new_revision;
        $rev->edit("#DELETED nuked\n" . $rev->muse_body);
        $rev->commit_version;
        $rev->publish_text;
        $deleted_text = $text;
    }
    $archive = $site->monthly_archives->find({ year => 2015, month => $month });
    is $archive->text_months->count, 0, "Count reset";
    $mech->get_ok('/monthly');
    $mech->content_lacks("monthly-list-item-2015-$month");
    $mech->get_ok("/monthly/2015/$month");
    $mech->content_contains("No text found!");
}

if (my $month = $site->monthly_archives->find({ year => 2015, month => 5 })) {
    is $month->titles->count, 1;
    my $title = $month->titles->first;
    is $title->newer_text->pubdate->month, 6;
    is $title->older_text->pubdate->month, 4;
}

for my $delete (0,0,1) {
    my $text = $deleted_text->discard_changes;
    my $rev = $text->new_revision;
    if ($delete) {
        $rev->edit("#DELETED nuked\n" . $rev->muse_body);
    }
    else {
        my $body = $rev->muse_body;
        $body =~ s/#DELETED.*?\n//g;
        $rev->edit($body);
    }
    $rev->commit_version;
    $rev->publish_text;
    $text->discard_changes;
    my $pubdate = $text->pubdate;
    $mech->get_ok("/monthly/" . $pubdate->year . '/' . $pubdate->month);
    if ($delete) {
        $mech->content_contains("No text found!");
    }
    else {
        $mech->content_contains($text->title);
    }
}

for (1..2) {
    $site->populate_monthly_archives;
    my $archive = $site->monthly_archives->find({ year => 2015, month => 5 });
    ok ($archive->titles->count, "Found the archives");
}



sub add_text {
    my ($args, $type, $no_cover) = @_;
    $type ||= 'text';
    my ($rev) = $site->create_new_text($args, $type);
    unless ($no_cover) {
        my $body = $rev->muse_body;
        my $attached = $rev->add_attachment(catfile(qw/t files shot.png/))->{attachment};
        $body = "#cover $attached\n#coverwidth 0.5\n" . $body;
        $rev->edit($body);
    }
    $rev->commit_version;
    $rev->publish_text;
}
