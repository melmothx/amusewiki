package AmuseWikiFarm::Log::Contextual;

use strict;
use warnings;
use base 'Log::Contextual';
use Log::Log4perl;
use File::Spec;

unless (Log::Log4perl->initialized) {
    my $dummy =<<'CONF';
log4perl.logger=INFO, Screen
log4perl.appender.Screen=Log::Dispatch::Screen
log4perl.appender.Screen.layout=Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern=%d %p - %c - %F{1}:%L - %m%n
CONF
    my $existing;
    my @confs = (
                 'log4perl.local.conf',
                 'log4perl.conf',
                );
    foreach my $conf (@confs) {
        my $path = File::Spec->rel2abs($conf);
        if (-f $path) {
            $existing = $path;
            last;
        }
    }
    Log::Log4perl->init($existing || \$dummy);
}

sub arg_default_logger {
    my ($self, $logger);
    return $logger if $logger;
    my $package = caller(3);
    return Log::Log4perl->get_logger($package);
}

sub default_import { qw(:log :dlog) }

1;
