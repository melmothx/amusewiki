package AmuseWikiFarm::Log::Contextual;

use strict;
use warnings;
use base 'Log::Contextual';
use Log::Log4perl;
use File::Spec;

# note: if you cange engine, please change the engine in
# AmuseWikiFarm.pm as well.

if (!Log::Log4perl->initialized) {
    my $conf;
    if (-f 'log4perl.local.conf') {
        $conf = 'log4perl.local.conf';
    }
    else {
        $conf = 'log4perl.conf';
    }
    Log::Log4perl->init_and_watch($conf, 60);
}

sub arg_default_logger {
    my ($self, $logger);
    return $logger if $logger;
    my $package = caller(3);
    return Log::Log4perl->get_logger($package);
}
sub default_import { qw(:log ) }

1;
