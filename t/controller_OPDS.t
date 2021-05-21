use utf8;
use strict;
use warnings;
use Test::More tests => 374;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(utf-8)";

use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;
use Test::Differences;
use DateTime;
use File::Spec::Functions qw/catfile catdir/;
use File::Copy::Recursive qw/dircopy/;
use File::Path qw/remove_tree make_path/;
use File::Copy qw/copy/;
use URI::Escape qw/uri_escape_utf8/;
use Data::Dumper::Concise;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $id = '0opds0';
my $src = catdir(qw/t test-repos/, $id);
my $dest = catdir(repo => $id);
remove_tree($dest);
unless (-d $dest) {
    dircopy($src, $dest); 
}
my $site = $schema->resultset('Site')->update_or_create({
                                               id => $id,
                                               locale => 'en',
                                               mode => 'blog',
                                               sitename => 'OPDS test',
                                               siteslogan => 'Test',
                                               a4_pdf => 0,
                                               pdf => 0,
                                               lt_pdf => 0,
                                               canonical => "$id.amusewiki.org",
                                               secure_site => 0,
                                              })->discard_changes;

$site->jobs->delete;
$site->update_db_from_tree(sub { diag join(' ', @_) });
$site->update({ last_updated => DateTime->new(year => 2016, month => 3, day => 1) });
while (my $j = $site->jobs->dequeue) {
    $j->dispatch_job;
    diag $j->logs;
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my @urls;
my $cats = $site->categories->active_only;
while (my $cat = $cats->next) {
    push @urls, { url => '/opds/category/' . $cat->type . '/' . $cat->uri,
                  contains => $cat->name,
                };
    push @urls, { url => '/opds/category/' . $cat->type . '/' . $cat->uri  . '/1',
                  contains => $cat->name,
                };
}

foreach my $url ({ url => '/opds' },
                 { url => '/opds/new' },
                 { url => '/opds/new/1' },
                 { url => '/opds/titles' },
                 { url => '/opds/titles/1' },
                 { url => '/opds/category/topic' },
                 { url => '/opds/category/author' },
                 @urls,
                ) {
    $mech->get_ok($url->{url});
    is $mech->content_type, "application/atom+xml";
    if (my $contains = $url->{contains}) {
        $mech->content_contains($contains);
    }
    diag $mech->content if $url->{verbose};
}

$mech->get('/opds');
my $expected =<< 'ATOM';
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>http://0opds0.amusewiki.org/opds</id>
  <link rel="self" href="http://0opds0.amusewiki.org/opds" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="OPDS test"/>
  <link rel="http://opds-spec.org/crawlable" href="http://0opds0.amusewiki.org/opds/crawlable" type="application/atom+xml;profile=opds-catalog;kind=acquisition" title="Titles"/>
  <link rel="search" href="http://0opds0.amusewiki.org/opensearch.xml" type="application/opensearchdescription+xml" title="Search"/>
  <link rel="start" href="http://0opds0.amusewiki.org/opds" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="OPDS test"/>
  <title>OPDS test</title>
  <updated>2016-03-01T00:00:00Z</updated>
  <icon>http://0opds0.amusewiki.org/favicon.ico</icon>
  <author>
    <name>OPDS test</name>
    <uri>http://0opds0.amusewiki.org</uri>
  </author>
  <entry>
    <title>New</title>
    <id>http://0opds0.amusewiki.org/opds/new</id>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">Latest entries</div>
    </content>
    <updated>2016-03-01T00:00:00Z</updated>
    <link rel="http://opds-spec.org/sort/new" href="http://0opds0.amusewiki.org/opds/new" type="application/atom+xml;profile=opds-catalog;kind=acquisition" title="New"/>
  </entry>
  <entry>
    <title>Titles</title>
    <id>http://0opds0.amusewiki.org/opds/titles</id>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">Full list of texts</div>
    </content>
    <updated>2016-03-01T00:00:00Z</updated>
    <link rel="subsection" href="http://0opds0.amusewiki.org/opds/titles" type="application/atom+xml;profile=opds-catalog;kind=acquisition" title="Titles"/>
  </entry>
  <entry>
    <title>Authors</title>
    <id>http://0opds0.amusewiki.org/opds/category/author</id>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">Authors</div>
    </content>
    <updated>2016-03-01T00:00:00Z</updated>
    <link rel="subsection" href="http://0opds0.amusewiki.org/opds/category/author" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="Authors"/>
  </entry>
  <entry>
    <title>Topics</title>
    <id>http://0opds0.amusewiki.org/opds/category/topic</id>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">Topics</div>
    </content>
    <updated>2016-03-01T00:00:00Z</updated>
    <link rel="subsection" href="http://0opds0.amusewiki.org/opds/category/topic" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="Topics"/>
  </entry>
</feed>
ATOM
unified_diff;
eq_or_diff ($mech->content, $expected, "Root ok");

$mech->get('/opds/category/author');
$mech->content_lacks('http://opds-spec.org/sort/new') or diag $mech->content;

$mech->get('/opds/titles');
$expected =<< 'ATOM';
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>http://0opds0.amusewiki.org/opds/titles/1</id>
  <link rel="self" href="http://0opds0.amusewiki.org/opds/titles/1" type="application/atom+xml;profile=opds-catalog;kind=acquisition" title="Titles"/>
  <link rel="http://opds-spec.org/crawlable" href="http://0opds0.amusewiki.org/opds/crawlable" type="application/atom+xml;profile=opds-catalog;kind=acquisition" title="Titles"/>
  <link rel="first" href="http://0opds0.amusewiki.org/opds/titles/1" type="application/atom+xml;profile=opds-catalog;kind=acquisition"/>
  <link rel="last" href="http://0opds0.amusewiki.org/opds/titles/5" type="application/atom+xml;profile=opds-catalog;kind=acquisition"/>
  <link rel="next" href="http://0opds0.amusewiki.org/opds/titles/2" type="application/atom+xml;profile=opds-catalog;kind=acquisition"/>
  <link rel="search" href="http://0opds0.amusewiki.org/opensearch.xml" type="application/opensearchdescription+xml" title="Search"/>
  <link rel="start" href="http://0opds0.amusewiki.org/opds" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="OPDS test"/>
  <link rel="up" href="http://0opds0.amusewiki.org/opds" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="OPDS test"/>
  <title>Titles</title>
  <updated>2016-03-01T00:00:00Z</updated>
  <icon>http://0opds0.amusewiki.org/favicon.ico</icon>
  <author>
    <name>OPDS test</name>
    <uri>http://0opds0.amusewiki.org</uri>
  </author>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-10</id>
    <title>Title 10 đćčšžĐĆČŠŽ</title>
    <updated>2016-01-10T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 10</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-10</uri>
    </author>
    <author>
      <name>A2 10</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-10</uri>
    </author>
    <summary>Subtitle 10</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-10.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-11</id>
    <title>Title 11</title>
    <updated>2016-01-11T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 11</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-11</uri>
    </author>
    <author>
      <name>A2 11</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-11</uri>
    </author>
    <summary>Subtitle 11</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-11.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-12</id>
    <title>Title 12</title>
    <updated>2016-01-12T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 12</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-12</uri>
    </author>
    <author>
      <name>A2 12</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-12</uri>
    </author>
    <summary>Subtitle 12</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-12.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-13</id>
    <title>Title 13</title>
    <updated>2016-01-13T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 13</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-13</uri>
    </author>
    <author>
      <name>A2 13</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-13</uri>
    </author>
    <summary>Subtitle 13</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-13.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-14</id>
    <title>Title 14</title>
    <updated>2016-01-14T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">ru</dc:language>
    <author>
      <name>A1 14</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-14</uri>
    </author>
    <author>
      <name>A2 14</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-14</uri>
    </author>
    <summary>Subtitle 14</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-14.epub" type="application/epub+zip"/>
  </entry>
</feed>
ATOM
eq_or_diff($mech->content, $expected, "titles ok");

$mech->get_ok('/opensearch.xml');

$mech->get_ok('/opds/search?query=a*');
$mech->content_contains(q{"http://0opds0.amusewiki.org/opds/search?query=a*&amp;page=2"});
$mech->get_ok('/opds/search?query=<>+OR+a*');
$mech->content_contains(q{"http://0opds0.amusewiki.org/opds/search?query=%3C%3E+OR+a*&amp;page=1"});

$mech->get_ok('/opds/search?query=' . uri_escape_utf8('Здра́вствуйте'));
$mech->content_contains(uri_escape_utf8('Здра́вствуйте'));

$mech->get_ok('/opds/search?query=OR+OR+OR+OR');

$expected =<<'XML';
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>http://0opds0.amusewiki.org/opds/search?query=OR+OR+OR+OR&amp;page=1</id>
  <link rel="self" href="http://0opds0.amusewiki.org/opds/search?query=OR+OR+OR+OR&amp;page=1" type="application/atom+xml;profile=opds-catalog;kind=acquisition" title="Search results"/>
  <link rel="http://opds-spec.org/crawlable" href="http://0opds0.amusewiki.org/opds/crawlable" type="application/atom+xml;profile=opds-catalog;kind=acquisition" title="Titles"/>
  <link rel="search" href="http://0opds0.amusewiki.org/opensearch.xml" type="application/opensearchdescription+xml" title="Search"/>
  <link rel="start" href="http://0opds0.amusewiki.org/opds" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="OPDS test"/>
  <link rel="up" href="http://0opds0.amusewiki.org/opds" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="OPDS test"/>
  <title>Search results</title>
  <updated>2016-03-01T00:00:00Z</updated>
  <icon>http://0opds0.amusewiki.org/favicon.ico</icon>
  <author>
    <name>OPDS test</name>
    <uri>http://0opds0.amusewiki.org</uri>
  </author>
</feed>
XML

eq_or_diff($mech->content, $expected, "search ok");

$mech->get_ok('/opds/search?query=<author>');
$expected = <<'XML';
  <opensearch:totalResults xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/">22</opensearch:totalResults>
  <opensearch:startIndex xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/">1</opensearch:startIndex>
  <opensearch:itemsPerPage xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/">10</opensearch:itemsPerPage>
XML

$mech->content_contains('searchTerms="%3Cauthor%3E"', "search terms escaped");
$mech->content_contains($expected, "opensearch ok");
$mech->content_contains(q{<link rel="self" href="http://0opds0.amusewiki.org/opds/search?query=%3Cauthor%3E&amp;page=1" type="application/atom+xml;profile=opds-catalog;kind=acquisition" title="Search results"/>},
                        "self ok");
$mech->get_ok(q{/opds/search?query="'<>});
$expected = <<'XML';
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>http://0opds0.amusewiki.org/opds/search?query=%22'%3C%3E&amp;page=1</id>
  <link rel="self" href="http://0opds0.amusewiki.org/opds/search?query=%22'%3C%3E&amp;page=1" type="application/atom+xml;profile=opds-catalog;kind=acquisition" title="Search results"/>
  <link rel="http://opds-spec.org/crawlable" href="http://0opds0.amusewiki.org/opds/crawlable" type="application/atom+xml;profile=opds-catalog;kind=acquisition" title="Titles"/>
  <link rel="search" href="http://0opds0.amusewiki.org/opensearch.xml" type="application/opensearchdescription+xml" title="Search"/>
  <link rel="start" href="http://0opds0.amusewiki.org/opds" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="OPDS test"/>
  <link rel="up" href="http://0opds0.amusewiki.org/opds" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="OPDS test"/>
  <title>Search results</title>
  <updated>2016-03-01T00:00:00Z</updated>
  <icon>http://0opds0.amusewiki.org/favicon.ico</icon>
  <author>
    <name>OPDS test</name>
    <uri>http://0opds0.amusewiki.org</uri>
  </author>
</feed>
XML

eq_or_diff($mech->content, $expected, "search with no results ok");

$mech->get_ok(q{/opds/crawlable});
$expected = <<'XML';
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>http://0opds0.amusewiki.org/opds/crawlable</id>
  <link rel="self" href="http://0opds0.amusewiki.org/opds/crawlable" type="application/atom+xml;profile=opds-catalog;kind=acquisition" title="Titles"/>
  <link rel="http://opds-spec.org/crawlable" href="http://0opds0.amusewiki.org/opds/crawlable" type="application/atom+xml;profile=opds-catalog;kind=acquisition" title="Titles"/>
  <link rel="search" href="http://0opds0.amusewiki.org/opensearch.xml" type="application/opensearchdescription+xml" title="Search"/>
  <link rel="start" href="http://0opds0.amusewiki.org/opds" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="OPDS test"/>
  <link rel="up" href="http://0opds0.amusewiki.org/opds" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="OPDS test"/>
  <title>Titles</title>
  <updated>2016-03-01T00:00:00Z</updated>
  <icon>http://0opds0.amusewiki.org/favicon.ico</icon>
  <author>
    <name>OPDS test</name>
    <uri>http://0opds0.amusewiki.org</uri>
  </author>
  <fh:complete xmlns:fh="http://purl.org/syndication/history/1.0"></fh:complete>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-31</id>
    <title>Title 31 &amp; test</title>
    <updated>2016-01-31T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 31</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-31</uri>
    </author>
    <author>
      <name>A2 31</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-31</uri>
    </author>
    <summary>Subtitle &amp; 31</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-31.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-30</id>
    <title>Title 30</title>
    <updated>2016-01-30T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 30</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-30</uri>
    </author>
    <author>
      <name>A2 30</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-30</uri>
    </author>
    <summary>Subtitle 30</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-30.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-29</id>
    <title>Title 29</title>
    <updated>2016-01-29T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 29</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-29</uri>
    </author>
    <author>
      <name>A2 29</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-29</uri>
    </author>
    <summary>Subtitle 29</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-29.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-28</id>
    <title>Title 28</title>
    <updated>2016-01-28T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 28</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-28</uri>
    </author>
    <author>
      <name>A2 28</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-28</uri>
    </author>
    <summary>Subtitle 28</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-28.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-27</id>
    <title>Title 27</title>
    <updated>2016-01-27T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 27</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-27</uri>
    </author>
    <author>
      <name>A2 27</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-27</uri>
    </author>
    <summary>Subtitle 27</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-27.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-26</id>
    <title>Title 26</title>
    <updated>2016-01-26T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 26</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-26</uri>
    </author>
    <author>
      <name>A2 26</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-26</uri>
    </author>
    <summary>Subtitle 26</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-26.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-25</id>
    <title>Title 25</title>
    <updated>2016-01-25T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 25</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-25</uri>
    </author>
    <author>
      <name>A2 25</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-25</uri>
    </author>
    <summary>Subtitle 25</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-25.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-24</id>
    <title>Title 24</title>
    <updated>2016-01-24T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 24</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-24</uri>
    </author>
    <author>
      <name>A2 24</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-24</uri>
    </author>
    <summary>Subtitle 24</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-24.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-23</id>
    <title>Title 23</title>
    <updated>2016-01-23T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 23</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-23</uri>
    </author>
    <author>
      <name>A2 23</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-23</uri>
    </author>
    <summary>Subtitle 23</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-23.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-22</id>
    <title>Title 22</title>
    <updated>2016-01-22T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 22</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-22</uri>
    </author>
    <author>
      <name>A2 22</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-22</uri>
    </author>
    <summary>Subtitle 22</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-22.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-21</id>
    <title>Title 21</title>
    <updated>2016-01-21T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 21</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-21</uri>
    </author>
    <author>
      <name>A2 21</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-21</uri>
    </author>
    <summary>Subtitle 21</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-21.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-20</id>
    <title>Title 20</title>
    <updated>2016-01-20T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 20</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-20</uri>
    </author>
    <author>
      <name>A2 20</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-20</uri>
    </author>
    <summary>Subtitle 20</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-20.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-19</id>
    <title>Title 19</title>
    <updated>2016-01-19T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 19</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-19</uri>
    </author>
    <author>
      <name>A2 19</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-19</uri>
    </author>
    <summary>Subtitle 19</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-19.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-18</id>
    <title>Title 18</title>
    <updated>2016-01-18T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 18</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-18</uri>
    </author>
    <author>
      <name>A2 18</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-18</uri>
    </author>
    <summary>Subtitle 18</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-18.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-17</id>
    <title>Title 17</title>
    <updated>2016-01-17T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 17</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-17</uri>
    </author>
    <author>
      <name>A2 17</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-17</uri>
    </author>
    <summary>Subtitle 17</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-17.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-16</id>
    <title>Title 16 (Đćčž àòé)</title>
    <updated>2016-01-16T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 16</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-16</uri>
    </author>
    <author>
      <name>A2 16</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-16</uri>
    </author>
    <summary>Subtitle 16</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-16.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-15</id>
    <title>Title 15</title>
    <updated>2016-01-15T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 15</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-15</uri>
    </author>
    <author>
      <name>A2 15</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-15</uri>
    </author>
    <summary>Subtitle 15</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-15.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-14</id>
    <title>Title 14</title>
    <updated>2016-01-14T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">ru</dc:language>
    <author>
      <name>A1 14</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-14</uri>
    </author>
    <author>
      <name>A2 14</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-14</uri>
    </author>
    <summary>Subtitle 14</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-14.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-13</id>
    <title>Title 13</title>
    <updated>2016-01-13T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 13</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-13</uri>
    </author>
    <author>
      <name>A2 13</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-13</uri>
    </author>
    <summary>Subtitle 13</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-13.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-12</id>
    <title>Title 12</title>
    <updated>2016-01-12T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 12</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-12</uri>
    </author>
    <author>
      <name>A2 12</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-12</uri>
    </author>
    <summary>Subtitle 12</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-12.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-11</id>
    <title>Title 11</title>
    <updated>2016-01-11T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 11</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-11</uri>
    </author>
    <author>
      <name>A2 11</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-11</uri>
    </author>
    <summary>Subtitle 11</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-11.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://0opds0.amusewiki.org/library/title-entry-10</id>
    <title>Title 10 đćčšžĐĆČŠŽ</title>
    <updated>2016-01-10T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>A1 10</name>
      <uri>http://0opds0.amusewiki.org/category/author/a1-10</uri>
    </author>
    <author>
      <name>A2 10</name>
      <uri>http://0opds0.amusewiki.org/category/author/a2-10</uri>
    </author>
    <summary>Subtitle 10</summary>
    <link rel="http://opds-spec.org/acquisition" href="http://0opds0.amusewiki.org/library/title-entry-10.epub" type="application/epub+zip"/>
  </entry>
</feed>
XML
eq_or_diff $mech->content, $expected, "Crawlable ok";
diag Dumper($mech->response);

$mech->get_ok('/opds/new');
$mech->content_contains('<link rel="http://opds-spec.org/image/thumbnail" href="http://0opds0.amusewiki.org/uploads/0opds0/thumbnails/t-e-test.png.thumb.png" type="image/png"/>');
$mech->content_contains('<link rel="http://opds-spec.org/image" href="http://0opds0.amusewiki.org/library/t-e-test.png" type="image/png"/>');
$mech->get_ok('/library/t-e-test.png');
$mech->get_ok('/uploads/0opds0/thumbnails/t-e-test.png.thumb.png');

$mech->get_ok('/opds/topics');
is $mech->uri->path, '/opds/category/topic';
$mech->content_contains(q{link rel="self" href="http://0opds0.amusewiki.org/opds/category/topic?page=1"});

# diag $mech->content;
# check the pagination
$mech->content_contains(q{href="http://0opds0.amusewiki.org/opds/category/topic?page=1"});
$mech->content_contains(q{href="http://0opds0.amusewiki.org/opds/category/topic?page=2"});


{
    $mech->get_ok('/opds/category/topic?page=1');
    is count_entries($mech->content), 5;
    $mech->content_contains(q{href="http://0opds0.amusewiki.org/opds/category/topic?page=1"});
    $mech->content_contains(q{href="http://0opds0.amusewiki.org/opds/category/topic?page=2"});
    $mech->get_ok('/opds/category/topic?page=2');
    $mech->content_contains(q{href="http://0opds0.amusewiki.org/opds/category/topic?page=1"});
    $mech->content_contains(q{href="http://0opds0.amusewiki.org/opds/category/topic?page=2"});
    is count_entries($mech->content), 2;
    $mech->get_ok('/opds/category/topic?page=3');
    $mech->content_contains(q{href="http://0opds0.amusewiki.org/opds/category/topic?page=1"});
    $mech->content_contains(q{href="http://0opds0.amusewiki.org/opds/category/topic?page=2"});
    is count_entries($mech->content), 0;
    $mech->get_ok('/opds/category/topic?page=4');
}

$mech->get_ok('/opds/topics/emile/1');
is $mech->uri->path, '/opds/category/topic/emile/1';


$mech->get_ok('/opds/authors');
is $mech->uri->path, '/opds/category/author';
$mech->get_ok('/opds/authors/a1-11');
is $mech->uri->path, '/opds/category/author/a1-11';
$mech->content_contains(q{link rel="up" href="http://0opds0.amusewiki.org/opds/category/author"});
$mech->get_ok('/opds/authors/a1-11/1');
is $mech->uri->path, '/opds/category/author/a1-11/1';

$site->update({ locale => 'ru' });
$mech->get_ok('/opds');
$mech->content_contains('Последние загруженные');

sub count_entries {
    my $feed = shift;
    my @entries;
    while ($feed =~ m{<entry>(.*?)</entry>}gs) {
        push @entries, $1;
    }
    return scalar(@entries);

}
