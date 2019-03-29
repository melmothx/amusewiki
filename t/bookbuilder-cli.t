#!perl

use strict;
use warnings;
use Test::More tests => 3;
use AmuseWikiFarm::Archive::BookBuilder;
use Data::Dumper::Concise;

{
    my $bb = AmuseWikiFarm::Archive::BookBuilder->new(centerchapter => 1,
                                                      imposed => 1,
                                                      centersection => 0);
    # diag Dumper($bb->as_job);
    my $cli = $bb->as_cli;
    like $cli, qr{fontsize=10};
    like $cli, qr{pdf-impose};
    like $cli, qr{--schema 2up};
    diag $bb->as_cli; 

}

done_testing;
