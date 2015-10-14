use strict;
use warnings;
use utf8;
use Test::More tests => 2;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";


unless (eval q{use Test::WWW::Mechanize::Catalyst 0.55; 1}) {
    plan skip_all => 'Test::WWW::Mechanize::Catalyst >= 0.55 required';
    exit 0;
}

use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use File::Copy qw/copy/;
use Text::Amuse::Compile::Utils qw/write_file read_file append_file/;
use Data::Dumper;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

my $site_id = '0beamer0';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, $site_id);
$site->update({ sl_pdf => 1,
                cgit_integration => 1,
              });
my $mech = Test::WWW::Mechanize::Catalyst
  ->new(catalyst_app => 'AmuseWikiFarm',
        host => $site->id . '.amusewiki.org');

use File::Path qw/make_path/;
my $destination = catdir($site->repo_root, qw/s ss/);
make_path($destination, { verbose => 1 }) unless -d $destination;
foreach my $muse ('slides.muse', 'slides-s-no.muse') {
    copy(catfile(qw/t files/, $muse), $destination)
      or die "Cannot t/files/$muse into $destination $!";
}
$site->update_db_from_tree;
ok (-f catfile($destination, 'slides.sl.pdf'), "Slides created");
ok (! -f catfile($destination, 'slides-s-no.sl.pdf'),
    "Slides not created if #slides no");

