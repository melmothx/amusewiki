package AmuseWikiFarm::Log::Contextual;

use strict;
use warnings;
use base 'Log::Contextual';
use Log::Log4perl;
use File::Spec;
use AmuseWikiFarm::Utils::LogConf;

# note: if you cange engine, please change the engine in
# AmuseWikiFarm.pm as well.

if (!Log::Log4perl->initialized) {
    Log::Log4perl->init(AmuseWikiFarm::Utils::LogConf::init_args);
}

sub arg_default_logger {
    my ($self, $logger);
    return $logger if $logger;
    my $package = caller(3);
    return Log::Log4perl->get_logger($package);
}

sub default_import { qw(:log :dlog) }

1;
