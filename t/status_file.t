#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 11;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Text::Amuse::Compile::Utils qw/write_file read_file/;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Text::Amuse::Compile;
use Fcntl qw/:flock/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0stfl0');

my ($revision) = $site->create_new_text({ uri => 'first-testx',
                                        title => 'Hello',
                                        lang => 'hr',
                                        textbody => 'blabla' }, 'text');

$revision->commit_version;
$revision->publish_text;

my $title = $revision->title->discard_changes;
my $file = $title->f_full_path_name;
my $status_file = $title->filepath_for_ext('status');

foreach my $f ($file, $status_file) {
    ok ($f);
    ok (-f $f, "$file exists");
}

my $status_line = read_file($status_file);
like $status_line, qr/^OK/, "status file ok";


ok (!$title->deleted, "Title is not deleted");
ok ($title->is_published);

# now change the status file

my $fh;
open($fh, '>', $status_file) or die $!;
Text::Amuse::Compile->_write_status_file($fh, 'FAILED');
undef $fh;

$site->index_file($file);

$title->discard_changes;

ok !$title->is_published, "File is not published";
is $title->status, 'deleted', "Status is deleted";
like $title->deleted, qr/compilation failed/i, "Found deletion reason" ;

open($fh, '>', $status_file) or die $!;
Text::Amuse::Compile->_write_status_file($fh, 'DELETED');

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

$site->index_file($file);

foreach my $w (@warnings) {
    diag $w;
}

my @found = grep { m/This should not happen/ } @warnings;

ok scalar(@found);

