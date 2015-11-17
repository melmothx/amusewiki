#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 3;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use File::Spec::Functions qw/catfile catdir/;
use File::Copy qw/copy/;
use File::Basename qw/basename/;
use File::Temp;
use Data::Dumper;

use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0htmlfile0');

{ 
    my ($rev, $error) = $site->create_new_text({ title => 'test',
                                                 lang => 'ru',
                                                 fileupload => catfile(qw/t files upload.html/),
                                               }, 'text');
    ok ($rev, "Revision created");
    like ($rev->muse_body, qr/Примерно до конца/, "File processed");
}

{ 
    my ($rev, $error) = $site->create_new_text({ title => 'test-1',
                                                 lang => 'ru',
                                                 fileupload => catfile(qw/t files shot.png/),
                                               }, 'text');
    ok (!$rev, "Revision not created");
}

