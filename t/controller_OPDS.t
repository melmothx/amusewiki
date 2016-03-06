use utf8;
use strict;
use warnings;
use Test::More;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(utf-8)";

use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;
use Test::Differences;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');
$site->update({ last_updated => DateTime->new(year => 2016, month => 3, day => 5)});
$site->titles->published_texts->update({ pubdate => DateTime->new(year => 2016, month => 3, day => 5)});
my $cats = $site->categories->active_only;

my @urls;
while (my $cat = $cats->next) {
    push @urls, { url => '/opds/' . $cat->type . 's/' . $cat->uri,
                  contains => $cat->name,
                };
    push @urls, { url => '/opds/' . $cat->type . 's/' . $cat->uri  . '/1',
                  contains => $cat->name,
                };
}

foreach my $url ({ url => '/opds' },
                 { url => '/opds/new' },
                 { url => '/opds/new/1' },
                 { url => '/opds/titles' },
                 { url => '/opds/titles/1' },
                 { url => '/opds/topics' },
                 { url => '/opds/authors' },
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
  <id>http://blog.amusewiki.org/opds</id>
  <link rel="self" href="http://blog.amusewiki.org/opds" type="application/atom+xml;profile=opds-catalog;kind=navigation"/>
  <link rel="start" href="http://blog.amusewiki.org/opds" type="application/atom+xml;profile=opds-catalog;kind=navigation"/>
  <title>A moderated wiki</title>
  <updated>2016-03-05T00:00:00Z</updated>
  <icon>http://blog.amusewiki.org/favicon.ico</icon>
  <author>
    <name>A moderated wiki</name>
    <uri>http://blog.amusewiki.org</uri>
  </author>
  <entry>
    <title>Novo</title>
    <id>http://blog.amusewiki.org/opds/new</id>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">Poslednji unosi</div>
    </content>
    <updated>2016-03-05T00:00:00Z</updated>
    <link rel="http://opds-spec.org/sort/new" href="http://blog.amusewiki.org/opds/new" type="application/atom+xml;profile=opds-catalog;kind=acquisition"/>
  </entry>
  <entry>
    <title>Naslovi</title>
    <id>http://blog.amusewiki.org/opds/titles</id>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">tekstovi po naslovu</div>
    </content>
    <updated>2016-03-05T00:00:00Z</updated>
    <link rel="subsection" href="http://blog.amusewiki.org/opds/titles" type="application/atom+xml;profile=opds-catalog;kind=acquisition" title="Naslovi"/>
  </entry>
  <entry>
    <title>Teme</title>
    <id>http://blog.amusewiki.org/opds/topics</id>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">tekstovi po temi</div>
    </content>
    <updated>2016-03-05T00:00:00Z</updated>
    <link rel="subsection" href="http://blog.amusewiki.org/opds/topics" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="Teme"/>
  </entry>
  <entry>
    <title>Autori</title>
    <id>http://blog.amusewiki.org/opds/authors</id>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">tekstovi po autoru</div>
    </content>
    <updated>2016-03-05T00:00:00Z</updated>
    <link rel="subsection" href="http://blog.amusewiki.org/opds/authors" type="application/atom+xml;profile=opds-catalog;kind=navigation" title="Autori"/>
  </entry>
</feed>
ATOM
unified_diff;
eq_or_diff ($mech->content, $expected, "Root ok");

$mech->get('opds/titles');
$expected =<< 'ATOM';
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>http://blog.amusewiki.org/opds/titles/1</id>
  <link rel="self" href="http://blog.amusewiki.org/opds/titles/1" type="application/atom+xml;profile=opds-catalog;kind=acquisition"/>
  <link rel="start" href="http://blog.amusewiki.org/opds" type="application/atom+xml;profile=opds-catalog;kind=navigation"/>
  <link rel="up" href="http://blog.amusewiki.org/opds" type="application/atom+xml;profile=opds-catalog;kind=navigation"/>
  <title>Naslovi</title>
  <updated>2016-03-05T00:00:00Z</updated>
  <icon>http://blog.amusewiki.org/favicon.ico</icon>
  <author>
    <name>A moderated wiki</name>
    <uri>http://blog.amusewiki.org</uri>
  </author>
  <fh:complete xmlns:fh="http://purl.org/syndication/history/1.0"></fh:complete>
  <entry>
    <id>http://blog.amusewiki.org/library/first-test</id>
    <title>My first test</title>
    <updated>2016-03-05T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>Cikla</name>
      <uri>http://blog.amusewiki.org/category/author/cikla</uri>
    </author>
    <author>
      <name>CPegulaX</name>
      <uri>http://blog.amusewiki.org/category/author/cpegulax</uri>
    </author>
    <author>
      <name>Ćao</name>
      <uri>http://blog.amusewiki.org/category/author/cao</uri>
    </author>
    <author>
      <name>ćPegula</name>
      <uri>http://blog.amusewiki.org/category/author/cpegula</uri>
    </author>
    <author>
      <name>ZMario</name>
      <uri>http://blog.amusewiki.org/category/author/zmario</uri>
    </author>
    <author>
      <name>ŽMarco</name>
      <uri>http://blog.amusewiki.org/category/author/zmarco</uri>
    </author>
    <summary>Test subtitle</summary>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml"><div>Note: This is just a test, however.</div>
<div>Source: My own work</div></div>
    </content>
    <link rel="http://opds-spec.org/acquisition" href="http://blog.amusewiki.org/library/first-test.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://blog.amusewiki.org/library/second-test</id>
    <title>Zu A Second test</title>
    <updated>2016-03-05T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>Ciao</name>
      <uri>http://blog.amusewiki.org/category/author/ciao</uri>
    </author>
    <author>
      <name>Cikla</name>
      <uri>http://blog.amusewiki.org/category/author/cikla</uri>
    </author>
    <author>
      <name>CPegulaX</name>
      <uri>http://blog.amusewiki.org/category/author/cpegulax</uri>
    </author>
    <author>
      <name>Ćao</name>
      <uri>http://blog.amusewiki.org/category/author/cao</uri>
    </author>
    <author>
      <name>ćPegula</name>
      <uri>http://blog.amusewiki.org/category/author/cpegula</uri>
    </author>
    <author>
      <name>More</name>
      <uri>http://blog.amusewiki.org/category/author/more</uri>
    </author>
    <author>
      <name>ZMario</name>
      <uri>http://blog.amusewiki.org/category/author/zmario</uri>
    </author>
    <author>
      <name>ŽMarco</name>
      <uri>http://blog.amusewiki.org/category/author/zmarco</uri>
    </author>
    <link rel="http://opds-spec.org/acquisition" href="http://blog.amusewiki.org/library/second-test.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>http://blog.amusewiki.org/library/do-this-by-yourself</id>
    <title>Ža Third test</title>
    <updated>2016-03-05T00:00:00Z</updated>
    <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
    <author>
      <name>Ciao</name>
      <uri>http://blog.amusewiki.org/category/author/ciao</uri>
    </author>
    <author>
      <name>Cikla</name>
      <uri>http://blog.amusewiki.org/category/author/cikla</uri>
    </author>
    <author>
      <name>Ćao</name>
      <uri>http://blog.amusewiki.org/category/author/cao</uri>
    </author>
    <author>
      <name>ćPegula</name>
      <uri>http://blog.amusewiki.org/category/author/cpegula</uri>
    </author>
    <author>
      <name>More</name>
      <uri>http://blog.amusewiki.org/category/author/more</uri>
    </author>
    <link rel="http://opds-spec.org/acquisition" href="http://blog.amusewiki.org/library/do-this-by-yourself.epub" type="application/epub+zip"/>
  </entry>
</feed>
ATOM
eq_or_diff($mech->content, $expected, "titles ok");

done_testing;
