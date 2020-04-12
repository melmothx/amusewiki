#!perl

use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use Test::More tests => 3;
use Cwd;
use File::Spec::Functions qw/catfile catdir/;
use AmuseWikiFarm::Utils::CgitSetup;
use Data::Dumper;
use AmuseWikiFarm::Schema;
use File::Path qw/remove_tree/;

my $amw_home = getcwd();
my %paths = (
             src => catdir($amw_home, qw/opt src/),
             www => catdir($amw_home, qw/root git/),
             cgitsrc => catdir($amw_home, qw/opt src cgit/),
             cgi => catfile($amw_home, qw/root git cgit.cgi/),
             gitsrc => catdir($amw_home, qw/opt src cgit git/),
             cache => catdir($amw_home, qw/shared cache cgit/),
             etc => catdir($amw_home, qw/shared etc/),
             cgitrc => catfile($amw_home, qw/shared etc cgitrc/),
             lib => catdir($amw_home, qw/opt usr/),
           );

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $cgit = AmuseWikiFarm::Utils::CgitSetup->new(schema => $schema);

my %got = map { $_ => $cgit->$_ } keys %paths;

is_deeply(\%got, \%paths, "Conf is matching");
print Dumper(\%paths);
my $target = $cgit->cgitrc;
remove_tree($cgit->etc, { verbose => 1 }) if -d $cgit->etc;
$cgit->create_skeleton;
$cgit->configure;
$cgit->configure;
opendir (my $dh, $cgit->etc) or die "Cannot open " . $cgit->etc . " $!";
my @paths = grep { /cgitrc/ } readdir $dh;
closedir $dh;
ok (-f $target, "$target found");
ok(@paths == 1, "No backup found, idempotens call to configure");
