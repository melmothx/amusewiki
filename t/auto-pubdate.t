#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 4;
use File::Spec::Functions qw/catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(utf-8)";

use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0autopubdate0');

{
    my ($revision, $error) = $site->create_new_text({ title => 'test' }, 'text');
    like $revision->muse_body, qr/^\#pubdate \d{4}/m, "Found pubdate in the body";
}

$site = $site->update_option_value(no_autoassign_pubdate => 1);

{
    my ($revision, $error) = $site->create_new_text({ title => 'test1' }, 'text');
    unlike $revision->muse_body, qr/^\#pubdate \d{4}/m, "Pubdate NOT present in the body";
}
{
    my ($revision, $error) = $site->create_new_text({
                                                     title => 'test2',
                                                     pubdate => 'invalid',
                                                    }, 'text');
    unlike $revision->muse_body, qr/^\#pubdate \d{4}/m, "Pubdate NOT present in the body";
}



$site = $site->update_option_value(no_autoassign_pubdate => 0);

{
    my ($revision, $error) = $site->create_new_text({ title => 'test3' }, 'text');
    like $revision->muse_body, qr/^\#pubdate \d{4}/m, "Pubdate present in the body";
}
