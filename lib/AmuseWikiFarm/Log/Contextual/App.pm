package AmuseWikiFarm::Log::Contextual::App;
use strict;
use warnings;
use 5.010001;
use AmuseWikiFarm::Log::Contextual;

# WARNING this module is dead-brained. Anyway, it appears to do the
# job correctly and it just intercepts the Catalyst core logging.

sub new {
    my ($class, @opts) = @_;
    my $self = {};
    Dlog_debug { "Passed $_ to constructor" } \@opts;
    bless $self, $class;
}

sub trace { my ($self, @stuff) = @_; log_trace { join("\n", @stuff) }; }
sub debug { my ($self, @stuff) = @_; log_debug { join("\n", @stuff) }; }
sub info  { my ($self, @stuff) = @_; log_info  { join("\n", @stuff) }; }
sub warn  { my ($self, @stuff) = @_; log_warn  { join("\n", @stuff) }; }
sub error { my ($self, @stuff) = @_; log_error { join("\n", @stuff) }; }
sub fatal { my ($self, @stuff) = @_; log_fatal { join("\n", @stuff) }; }
sub abort   { 0 };
sub levels  { 0 };
sub enable  { 0 };
sub disable { 0 };
sub is_trace { 1 };
sub is_debug { 1 };
sub is_info  { 1 };
sub is_warn  { 1 };
sub is_error { 1 };
sub is_fatal { 1 };

1;
