#!perl

# This is probably a redundant test, but given that it's a delicate
# part of the code, better safe than sorry.
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use utf8;
use strict;
use warnings;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Text::Amuse::Compile::Utils qw/write_file/;

use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Test::More tests => 5;
use Path::Tiny;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0symlinks0');

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my $css = catfile($site->path_for_site_files, 'local.css');
write_file($css, '/* */');
my $js = catfile($site->path_for_site_files, 'local.js');
unlink $js if -f $js;
symlink $css, $js;

ok ($site->has_site_file('local.css'));
ok ($site->has_site_file('local.js'));
ok (-f $js && -l $js, "$js exists and it's a symlink");


$mech->get_ok('/sitefiles/' . $site->id . '/local.css');
$mech->get('/sitefiles/' . $site->id . '/local.js');
is $mech->status, 404, "Symlink return a 404";


# when pulling a git, check if there are symlinks. If they are
# outside of the tree, remove them

my $local = Path::Tiny->tempdir(CLEANUP => 0);
my $git = Git::Wrapper->new("$local");
$git->clone($site->remote_repo_root, "$local");
diag "Using $local";
die "Not cloned" unless $local->child('.git')->exists;

CREATE: {
    my $count = 0;
    my @paths;
    foreach my $f ("../../../../../../../../../../../../../etc/passwd",
                   "/etc/passwd") {
        my $target = path($local, "pwd" . $count++);
        symlink $f, "$target";
        $git->add("$target");
        push @paths, $target;
    }
    $git->commit({ message => "Symlink attack" });
    $git->push;
    $mech->get_ok($site->git_notify_url);
    while (my $j = $site->jobs->dequeue) {
        $j->dispatch_job;
        diag $j->logs;
    }
    $git->pull;
    diag "Pulling now";
    foreach my $p (@paths) {
        ok !$p->exists, "$p is gone now";
    }
    ok scalar(grep { /Removed symlinks/ } $git->show), "Found the commit removing links";
}


