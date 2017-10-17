#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 227;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use AmuseWikiFarm::Archive::BookBuilder;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0cformats0';
my $site = create_site($schema, $site_id);

foreach my $type (qw/text special/) {
    my ($rev, $err) =  $site->create_new_text({ author => 'pinco',
                                                title => 'pallino',
                                                lang => 'en',
                                              }, $type);
    die $err if $err;
    $rev->edit($rev->muse_body . "\n\n some more text for the masses\n");
    $rev->commit_version;
    $rev->publish_text;
}

ok !$site->jobs->pending->build_custom_format_jobs->count;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
$mech->get_ok('/');
$mech->get('/settings/formats');
is $mech->status, '401';
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
is $mech->status, '200';

my @cfs;
foreach my $f (qw/epub pdf/) {
    $mech->get_ok('/settings/formats');
    my $name = "my custom format $f";
    $mech->submit_form(with_fields => {
                                       format_name => $name,
                                      });
    $mech->content_contains($name);
    $mech->submit_form(with_fields => {
                                       format_name => $name,
                                       format => $f,
                                      },
                       button => 'update',
                      );
    $mech->content_contains($name);
    my $cf = $site->custom_formats->active_only->search({ bb_format => $f })->first;
    ok($cf, "Found the format");
    push @cfs, $cf;
}

foreach my $cf (@cfs) {
    my $name = $cf->format_name;
    $mech->get_ok('/settings/formats');
    $mech->submit_form(form_id => 'format-activate-' . $cf->custom_formats_id );
    $mech->get_ok('/admin/sites/edit/' . $site->id) or die;
    $mech->content_lacks($name);
    $mech->get_ok('/user/site');
    $mech->content_lacks($name);
    $mech->get_ok('/settings/formats');
    $mech->submit_form(form_id => 'format-activate-' . $cf->custom_formats_id);
    $mech->get_ok('/admin/sites/edit/' . $site->id);
    $mech->content_contains($name);
    $mech->get_ok('/user/site');
    $mech->content_contains($name);
    ok $cf->bookbuilder;
}

foreach my $type (qw/text special/) {
    my ($rev, $err) =  $site->create_new_text({ author => 'new-author',
                                                title => 'new-text',
                                                lang => 'en',
                                              }, $type);
    die $err if $err;
    $rev->edit($rev->muse_body . "\n\n some more text for the masses\n");
    $rev->commit_version;
    $rev->publish_text;
}

ok $site->jobs->pending->build_custom_format_jobs->count;
while (my $job = $site->jobs->dequeue) {
    $job->dispatch_job;
    is $job->status, 'completed';
    ok($job->started) and diag $job->started;
    ok($job->completed) and diag $job->completed;
    diag $job->logs;
}



my @links;
my @gen_files;

foreach my $text ($site->titles->all) {
    diag $text->uri;
    diag $text->f_full_path_name;
    ok $text->parent_dir and diag $text->parent_dir;
    ok -d $text->parent_dir;
    $mech->get_ok($text->full_uri);
    foreach my $cf (@cfs) {
        $mech->get_ok($text->full_uri);
        if ($text->title eq 'pallino') {
            $mech->content_lacks($cf->format_name);
        }
        elsif ($text->f_class eq 'special') {
            $mech->get_ok($text->full_uri . '.' . $cf->extension);
        }
        else {
            $mech->content_contains($cf->format_name);
            $mech->get_ok($text->full_uri . '.' . $cf->extension);
        }
    }
    foreach my $cf (@cfs) {
        if ($text->title eq 'pallino') {
            ok $cf->needs_compile($text);
        }
        else {
            ok !$cf->needs_compile($text), $cf->format_name . " already built for " . $text->full_uri;
        }
        my $out = $cf->compile($text, sub { diag @_ });
        ok $out, "Produced $out" or die;
        ok (-f $out, "$out was produced");
        ok (!$cf->needs_compile($text));
        push @links, $text->full_uri . '.' . $cf->extension;
        $mech->get_ok($text->full_uri . '.' . $cf->extension);
        my $ext = $cf->extension;
        my $file = $text->f_full_path_name;
        $file =~ s/\.muse\z/.$ext/;
        is($out, $file, "$file ok");
        push @gen_files, $file;
        $mech->get_ok($text->full_uri);
        $mech->content_contains($cf->format_name) if $text->is_regular;
        diag "Removing $file";
        unlink $file or die "Cannot unlink $file $!";
        $mech->get_ok($text->full_uri);
        $mech->content_lacks($cf->format_name);
    }
}

{
    foreach my $file (@gen_files) {
        ok(! -f $file, "$file doesn't exist");
    }
    diag "Checking if the files are generated";
    $site->compile_and_index_files([keys %{ $site->repo_find_files }]);

    ok $site->jobs->pending->build_custom_format_jobs->count;
    while (my $job = $site->jobs->dequeue) {
        $job->dispatch_job;
        is $job->status, 'completed';
        diag $job->logs;
    }
    foreach my $old_j ($site->jobs) {
        diag "Deleting job" . $old_j->id, ' ' , $old_j->task;
        $old_j->delete;
    }
    foreach my $link (@links) {
        $mech->get_ok($link);
    }
    foreach my $file (@gen_files) {
        ok(-f $file, "$file exists now");
    }
}

# and a rebuild
{
    foreach my $file (@gen_files) {
        ok(unlink $file, "$file removed");
    }
    foreach my $title ($site->titles->all) {
        $site->jobs->enqueue(rebuild => { id => $title->id }, 0);
        my $job = $site->jobs->dequeue;
        $job->dispatch_job;
        is $job->status, 'completed';
    }
    foreach my $file (@gen_files) {
        ok(-f $file, "$file exists now");
    }
}

# and a deletion
{
    foreach my $file (@gen_files) {
        ok(-f  $file, "$file present");
    }
    foreach my $del ($site->titles->all) {
        $del->update({ deleted => 'removed' });
        foreach my $cf (@cfs) {
            $cf->compile($del);
        }
    }
    foreach my $file (@gen_files) {
        ok(! -f  $file, "$file removed");
    }
}

diag Dumper(\@gen_files, \@links);

$site->delete;
is($schema->resultset('CustomFormat')->search({ site_id => $site_id })->count, 0,
   "Custom format is gone after site deletion");

