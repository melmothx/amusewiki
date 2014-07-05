#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Data::Dumper;
use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use File::Slurp qw/read_file write_file/;
use AmuseWikiFarm::Schema;
use File::Path qw/make_path/;

use Test::More tests => 10;

my $site_id = '0sf0';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, $site_id);
$site->pdf(1);
$site->update->discard_changes;

# this muse will not compile because the list is too deep
my $faulty_muse =<<'EOF';
#title Fail

 1. my
    2. deep
       3. level
          4. deep
             5. deep
                6. deep

EOF

my $wd = catdir($site->repo_root, 'a', 'at');
make_path($wd);
my $name = 'a-test';
my $target = catfile($wd, $name . '.muse');
write_file($target, { binmode => ':encoding(utf-8)' }, $faulty_muse);

$site->update_db_from_tree;

check_failure($name);

# then, create a revision and publish it.

my ($rev) = $site->create_new_text({
                                    uri => 'a-test-2',
                                    title => 'Fail',
                                   }, 'text');

$rev->edit($faulty_muse);

$rev->commit_version;

$rev->publish_text;

check_failure('a-test-2');



sub check_failure {
    my $uri = shift;

    my $text = $site->titles->find({ uri => $uri, f_class => 'text'});
    ok $text, "Found the text";
    is $text->title, 'Fail', "Found the title";
    is $text->status, 'deleted', "Status is deleted";
    like $text->deleted, qr/compilation failed/i, "Deletion was set";

    my $statusline = read_file(catfile($wd, $uri . '.status'));
    like $statusline, qr/^FAILED/, "Status line reports failure";
}




