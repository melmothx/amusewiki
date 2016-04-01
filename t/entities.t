#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 18;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use File::Path qw/make_path/;
use File::Copy qw/copy/;
use Data::Dumper;
use Text::Amuse::Compile::Utils qw/write_file/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Utils::LexiconMigration;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";


my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0ent0';
my $site = create_site($schema, $site_id);
$site->multilanguage('en it hr');
$site->fixed_category_list("geo lines war");
$site->secure_site(0);
$site->update->discard_changes;

my $root = $site->repo_root;
my $filedir = catdir($root, qw/a at/);
make_path($filedir);
make_path($site->path_for_site_files);

my $muse = <<'MUSE';
#title <title> "'hello'"
#topics "'topic'", war, geo, lines
#author <author>
#lang en

Hello there

MUSE

write_file(catfile($root, qw/a at a-test.muse/), $muse);

$site->update_db_from_tree;

copy(catfile(qw/t entities.json/), $site->lexicon_file) or die $!;

ok $site->lexicon;
print Dumper($site->lexicon);
AmuseWikiFarm::Utils::LexiconMigration::convert($site->lexicon, $site->locales_dir);

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");

$mech->get_ok('/set-language?lang=hr');
$mech->content_contains('Geografija kontrole');
$mech->content_lacks('&amp;quot; i&#39; &amp;lt;državni&amp;gt; &amp;amp;');
$mech->content_contains(q{Ratovi&quot; i&#39; &lt;državni&gt; &amp; terorizam});

$mech->get_ok('/topics');
$mech->content_like(qr/class="list-group-item\ clearfix".*Ratovi&quot;\ i&\#39;\s*
                       &lt;državni&gt;\ &amp;\ terorizam/sx,
                    "Topics escaped in listing") or diag $mech->content;
$mech->content_like(qr/class="list-group-item\ clearfix"
                       .*
                       <strong>&quot;&\#39;topic&\#39;&quot;\s*<\/strong>/sx,
                    "Found the topic in list correctly escaped");


$mech->get_ok('/topics/war');
$mech->content_contains(q{<title>Ratovi&quot; i'  &amp; terorizam | </title>});
$mech->content_contains(q{<h2>Ratovi&quot; i&#39; &lt;državni&gt; &amp; terorizam}) or diag $mech->content;

$mech->get_ok('/topics/topic');
# title is escaped with | html, so "'" is preserved
$mech->content_like(qr/<title>&quot;'topic'&quot;/) or diag $mech->content;
$mech->content_contains(q{<h2>&quot;&#39;topic&#39;&quot;});

$mech->get_ok('/library/a-test');
$mech->content_contains(q{<title> &quot;'hello'&quot; | </title>});
$mech->get_ok('/debug_loc');
my $expected = <<'TXT';
&lt;hello \there&gt;
&lt;hello \\&quot;&#39;there&gt;
<hello>
&lt;hello&gt;
<hello>
&lt;hello&gt;
&lt;hello&gt;
TXT
is $mech->content, $expected, "Localization methods appears ok";
