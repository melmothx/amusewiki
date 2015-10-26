package AmuseWikiFarm::Utils::LogConf;

use strict;
use warnings;
use utf8;
use File::Spec;

sub init_args {
    my $dummy =<<'CONF';
log4perl.logger=DEBUG, Screen
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
    if ($existing) {
        print "Using conf $existing\n";
    }
    else {
        print "Using dummy conf\n";
    }
    return $existing || \$dummy;
}

1;
