package AmuseWikiFarm::Utils::Paginator::Object;

use strict;
use warnings;

use Moo;
use Types::Standard qw/Str ArrayRef Maybe/;

=head1 NAME

AmuseWikiFarm::Utils::Paginator::Object - Paginator object for AmuseWiki

=cut

has items => (is => 'ro', required => 1, isa => ArrayRef);
has next_url => (is => 'ro', isa => Maybe[Str]);
has prev_url => (is => 'ro', isa => Maybe[Str]);
has current_url => (is => 'ro', required => 1, isa => Str);

sub needed {
    my $self = shift;
    if (@{$self->items} > 1) {
        return 1;
    }
    else {
        return 0;
    }
}

1;
