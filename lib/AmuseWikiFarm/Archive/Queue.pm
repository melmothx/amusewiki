package AmuseWikiFarm::Archive::Queue;
use utf8;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

use JSON;
use DateTime;

=head2 site

The schema object.

=cut

has dbic => (
             isa => 'Object',
             is => 'ro',
             required => 1,
            );

sub bookbuilder_add {
    return;
}

__PACKAGE__->meta->make_immutable;

1;
