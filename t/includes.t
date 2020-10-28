#!perl

use utf8;
use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Path::Tiny;
use File::Spec::Functions qw/catdir/;
use Test::More tests => 46;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Data::Dumper::Concise;
use AmuseWikiFarm::Archive::BookBuilder;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );



my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0inc0');

foreach my $d ({
                sorting_pos => 0,
                directory => $site->repo_root,
               },
               {
                sorting_pos => 1,
                directory => path('t')->absolute,
               }) {
    $site->add_to_include_paths($d);
}

is_deeply $site->amuse_include_paths, [ $site->repo_root, path('t')->absolute ];

ok -d $site->repo_root;

path($site->repo_root)->child('try-another.txt')->spew_utf8(<<'MUSE');

# example
This is a configuration file

MUSE

my $check = qr{snippet.*configuration file}s;
my $leftover = qr{try-me\.muse.*try-another\.txt}s;

{
    my $revision = $site->create_new_text({ uri => 'first', title => "First" }, 'text');
    $revision->edit(<<'MUSE');
#title First
#lang en

~~

#include include/try-me.muse

{{{
#include try-another.txt
}}}


MUSE
    $revision->commit_version;
    $revision->publish_text(sub { diag @_ });
    like $revision->muse_doc->as_html, $check;
    unlike $revision->muse_doc->as_html, $leftover;
    like $revision->muse_doc->as_latex, $check;
    unlike $revision->muse_doc->as_latex, $leftover;
    ok scalar($revision->muse_doc->included_files);
    diag $revision->muse_doc->as_html;
    diag $revision->muse_doc->as_latex;

    my $title = $revision->title;
    unlike $title->muse_body, $check;;
    like $title->muse_body, qr{#include.*#include}s;
    like $title->html_body, $check;
    unlike $title->html_body, $leftover;
    is $title->included_files->count, 2;
    foreach my $i ($title->included_files) {
      diag Dumper({ $i->get_columns });
    }
    foreach my $ext (qw/html tex/) {
        my $f = $title->filepath_for_ext($ext);
        my $body = path($f)->slurp_utf8;
        like $body, $check, "$f is fine for $check";
        unlike $body, $leftover;
    }
    ok scalar($title->muse_object->included_files);
    diag Dumper([ $title->muse_object->included_files ]);
    is_deeply(
              [
               $title->muse_object->included_files
              ],
              [
               path('t/include/try-me.muse')->absolute,
               path('repo/0inc0/try-another.txt')->absolute,
              ]);
}

{
    my $bb = AmuseWikiFarm::Archive::BookBuilder->new(site => $site,
                                                      job_id => 666999,
                                                     );
    my %opts = $bb->compiler_options;
    is_deeply $opts{include_paths}, $site->amuse_include_paths;
    $bb->add_text('first');
    my $out = $bb->compile(sub { diag @_ });
    diag $out;
    my $tex = extract_file(path(bbfiles => $bb->sources_filename)->stringify, 'first.tex');
    like $tex, $check, "BB produced file matches $check";
    unlike $tex, $leftover;
}

{
    my $bb = AmuseWikiFarm::Archive::BookBuilder->new(site => $site,
                                                      job_id => 666998,
                                                      title => 'Test',
                                                     );
    my %opts = $bb->compiler_options;
    is_deeply $opts{include_paths}, $site->amuse_include_paths;
    $bb->add_text('first');
    $bb->add_text('first');
    my $out = $bb->compile(sub { diag @_ });
    diag $out;
    my $tex = extract_file(path(bbfiles => $bb->sources_filename)->stringify, '666998.tex');
    like $tex, qr{$check.*$check}s, "BB produced file matches $check.*$check (double text)";
    unlike $tex, $leftover;
}

# test the bumping.
{
    diag "Testing if the changes in an included file trigger a job";
    $site->jobs->delete;
    sleep 2;

    is $site->update_db_from_tree_async(sub { diag @_ })->total_jobs, 0, "Nothing changed";

    # modify the file.
    path($site->repo_root)->child('try-another.txt')->append_utf8("\n\npippo!!!\n");

    my $bulk = $site->update_db_from_tree_async(sub { diag @_ });
    diag Dumper($bulk->expected_documents);
    is $bulk->total_jobs, 1, "Found the job";

    while (my $j = $site->jobs->dequeue) {
        $j->dispatch_job;
        diag $j->logs;
    }
    my $title = $site->titles->find({ uri => 'first' });
    like $title->html_body, qr/pippo\!\!\!/;
    is $site->update_db_from_tree_async(sub { diag @_ })->total_jobs, 0, "Nothing changed";
}

# now remove the includes and try again.

$site->include_paths->delete;
{
    my $bb = AmuseWikiFarm::Archive::BookBuilder->new(site => $site,
                                                      job_id => 666997,
                                                     );
    $bb->add_text('first');
    $bb->compile(sub { diag @_ });
    my $tex = extract_file(path(bbfiles => $bb->sources_filename)->stringify, 'first.tex');
    unlike $tex, qr{$check}s, "BB produced file doesn't match $check";
    like $tex, $leftover, "Not included";
}

{
    my $bb = AmuseWikiFarm::Archive::BookBuilder->new(site => $site,
                                                      job_id => 666996,
                                                      title => 'Test');
    $bb->add_text('first');
    $bb->add_text('first');
    $bb->compile(sub { diag @_ });
    my $tex = extract_file(path(bbfiles => $bb->sources_filename)->stringify, '666996.tex');
    unlike $tex, $check, "BB produced file doesn't match $check";
    like $tex, qr{$leftover.*$leftover}s, "Not included";
}

{
    my $title = $site->titles->find({ uri => 'first' });
    my $revision = $title->new_revision;
    $revision->edit($revision->muse_body . "\n\n");
    $revision->commit_version;
    $revision->publish_text(sub { diag @_ });
    unlike $revision->muse_doc->as_html, $check;
    like $revision->muse_doc->as_html, $leftover;
    ok !scalar($revision->muse_doc->included_files);
    $title = $title->get_from_storage;
    is $title->included_files->count, 0;
    like $title->html_body, $leftover;
    foreach my $ext (qw/html tex/) {
        my $f = $title->filepath_for_ext($ext);
        my $body = path($f)->slurp_utf8;
        unlike $body, $check;
        like $body, $leftover;
    }
    ok !scalar($title->muse_object->included_files);
}

sub extract_file {
    my ($path, $target) = @_;
    my $extractor = Archive::Zip->new;
    ok ($extractor->read($path) == AZ_OK, "Zip can be read");
    my ($file) = $extractor->membersMatching(qr{\Q$target\E$});
    return $extractor->contents($file->fileName);
}

