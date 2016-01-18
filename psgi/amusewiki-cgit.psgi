#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw/$Bin/;
use Plack::App::WrapCGI;
use File::Spec;
my $cgitrc = File::Spec->rel2abs(File::Spec->catfile(qw/opt etc cgitrc/));
die "No cgitrc found" unless -f $cgitrc;

%ENV = (
        CGIT_CONFIG => $cgitrc,
       );

my $app = Plack::App::WrapCGI->new(script => "/usr/lib/cgit/cgit.cgi",
                                   execute => 1)->to_app;
