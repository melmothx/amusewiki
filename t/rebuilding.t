#!perl

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use utf8;
use strict;
use warnings;
use AmuseWikiFarm::Schema;
use Test::More tests => 19;
use File::Spec::Functions;
use Cwd;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');
ok ($site, "site found");

my $init = catfile(getcwd(), qw/script jobber.pl/);
# kill the jobber if running
system($init, 'stop');
my $text = $site->titles->published_texts->first;
$site->jobs->enqueue(rebuild => { id => $text->id }, 15);
sleep 1;
$site->jobs->enqueue(testing => { id => $text->id }, 10);

my @exts = (qw/pdf epub zip tex html/);
my %ts;
foreach my $ext (@exts) {
    my $file = $text->filepath_for_ext($ext);
    ok (-f $file, "$file exists");
    $ts{$ext} = (stat($file))[9];
}

{
    my $job = $site->jobs->dequeue;
    is $job->task, 'testing', "First dispatched job is the higher priority";
    $job->dispatch_job;
    is $job->status, 'completed';
}
{
    my $job = $site->jobs->dequeue;
    is $job->task, 'rebuild';
    $job->dispatch_job;
    is $job->status, 'completed';
    diag $job->logs;
    foreach my $ext (qw/tex pdf zip/) {
        like $job->logs, qr/Created .*\.\Q$ext\E/;
        ok (-f $text->filepath_for_ext($ext), "$ext exists");
        my $newts = (stat($text->filepath_for_ext($ext)))[9];
        ok ($newts > $ts{$ext}, "$ext updated");
    }
}
