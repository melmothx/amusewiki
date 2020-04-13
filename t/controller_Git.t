use strict;
use warnings;
use utf8;
use Test::More tests => 52;
use URI::Escape;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";

use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use Text::Amuse::Compile::Utils qw/write_file read_file append_file/;
use Data::Dumper;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

my $site_id = '0gitz0';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, $site_id);
$site->update({ cgit_integration => 1 });
my $othersite = create_site($schema, '0gitx0');
$othersite->update({ cgit_integration => 1 });

my $mech = Test::WWW::Mechanize::Catalyst
  ->new(catalyst_app => 'AmuseWikiFarm',
        host => $site->id . '.amusewiki.org');

my @traversals =  ('/git/' . $site->id . '/../' . $othersite->id,
                   '/git/' . $site->id . '/' . uri_escape('../') . $othersite->id,
                   '/git/' . $site->id . '/' . uri_escape(uri_escape('../')) . $othersite->id,
                   '/git/' . $site->id . '/' . uri_escape('../', '%./') . $othersite->id,
                   '/git/' . $site->id . '/' . uri_escape(uri_escape('../', '%./'), '%./') . $othersite->id,
                   '/git/' . $site->id . '/tree/' . '../../' . $othersite->id,
                   '/git/' . $site->id . '/tree/' . uri_escape('../../') . $othersite->id,
                   '/git/' . $site->id . '/tree/' . uri_escape(uri_escape('../../')) . $othersite->id,
                   '/git/' . $site->id . '/tree/' . uri_escape('../../', '%./') . $othersite->id,
                   '/git/' . $site->id . '/tree/' . uri_escape(uri_escape('../../', '%./'), '%./') . $othersite->id,
                  );

foreach my $traversal (@traversals) {
    diag "Testing $traversal";
    $mech->get($traversal);
    is $mech->status, '400';
    $mech->content_like(qr{\ABad});
}


$mech->get('/git/0gitz0');
foreach my $text ({
                   title => "Zdravo Hello àààà",
                   author => "Nemò",
                   textbody => "<p>àààà</p><p>čččččč</p>",
                   lang => 'hr',
                   type => 'special',
                  },
                  {
                   title => "Ciao parappappaà",
                   author => "Nitko džiko",
                   textbody => "<p>22222 àààà 2222222</p><p>333333 čččččč 33333</p>",
                   lang => 'it',
                  },
                  {
                   title => "De àààà",
                   textbody => "<p>111111111 àààà</p><p>xxxxxxxx čččččč 3333333</p>",
                   lang => 'de',
                  }) {
    my $type = delete $text->{type} || 'text';
    my ($revision, $error) =  $site->create_new_text($text, $type);
    ok $revision->id, "Found revision";
    $revision->edit({
                     fix_links => 1,
                     fix_typography => 1,
                     body => $revision->muse_body,
                    });
    $revision->commit_version;
    my $uri = $revision->publish_text;
    diag "Published $uri";
    $mech->get_ok($uri);
    if ($type eq 'special') {
        my $special_path = $uri;
        $special_path =~ s/special/specials/;
        $mech->get_ok("/git/0gitz0/log" . $special_path . '.muse');
    }
    else  {
        ok($mech->follow_link(url_regex => qr{/git/}), "link ok");
    }
    diag $mech->uri->path;
    $mech->content_contains($text->{title}, "Found the title");
    ok($mech->follow_link(text => 'tree'), "link_ok");
    diag $mech->uri->path;
    my $body_re = $text->{textbody};
    $body_re =~ s!</?p>!.*!g;
    $mech->content_like(qr{$body_re}s);
    ok($mech->follow_link(text => 'plain'), "link ok");
    diag $mech->uri->path;
    $mech->content_like(qr{$body_re}s);
}
COMMON: {
    $mech->get_ok('/git');
    $site->update({ cgit_integration => 0 });
    $mech->get_ok($site->titles->published_texts->first->full_uri);
    $mech->content_lacks("/git/");
    $mech->get('/git');
    is $mech->status, 401;
    ok $mech->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root' }) or die;
    $mech->get_ok('/git');
    $mech->get_ok($site->titles->published_texts->first->full_uri);
    $mech->content_contains("/git/");
}
