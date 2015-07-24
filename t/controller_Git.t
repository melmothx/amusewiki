use strict;
use warnings;
use utf8;
use Test::More tests => 26;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";


unless (eval q{use Test::WWW::Mechanize::Catalyst 0.55; 1}) {
    plan skip_all => 'Test::WWW::Mechanize::Catalyst >= 0.55 required';
    exit 0;
}


use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use Text::Amuse::Compile::Utils qw/write_file read_file append_file/;
use Data::Dumper;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

my $site_id = '0gitz0';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, $site_id);
ok ($site);

ok ($site->repo_is_under_git, "db knows about git");
$site->cgit_integration(1);
$site->update({ cgit_integration => 1 });

my $mech = Test::WWW::Mechanize::Catalyst
  ->new(catalyst_app => 'AmuseWikiFarm',
        host => $site->id . '.amusewiki.org');

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
