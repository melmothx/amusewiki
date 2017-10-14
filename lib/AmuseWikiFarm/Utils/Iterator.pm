package AmuseWikiFarm::Utils::Iterator;

use utf8;
use strict;
use warnings;
use Moo;
use Types::Standard qw/Int ArrayRef/;

=head1 NAME

AmuseWikiFarm::Utils::Iterator - simple iterator

=head1 SYNOPSIS

  my $iter = AmuseWikiFarm::Utils::Iterator->new([1,2,3]);
  while (my $i = $iter->next) {
    print "$i\n";
  }
  print $iter->count;
  $iter->reset;
  while (my $i = $iter->next) {
    print "$i\n";
  }
  

=head1 CONSTRUCTOR

The constructor accepts an arrayref only.

=head1 METHODS

These are the well-known methods for an iterator.

=head2 count

=head2 next

=head2 reset

=cut

has _array => (is => 'ro', isa => ArrayRef);
has count => (is => 'ro', isa => Int);
has _pointer => (is => 'rw', isa => Int, default => 0);

sub BUILDARGS {
    my ($class, $arg) = @_;
    die "Missing arrayref passed to the constructor" unless $arg && (ref($arg) eq 'ARRAY');
    return { _array => [ @$arg ],
             count => scalar(@$arg) };
}

sub next {
    my $self = shift;
    my $i = $self->_pointer;
    # increment
    $self->_pointer($i + 1);
    if ($i < $self->count) {
        return $self->_array->[$i];
    }
    else {
        return undef;
    }
}

sub reset {
    shift->_pointer(0);
}

1;
