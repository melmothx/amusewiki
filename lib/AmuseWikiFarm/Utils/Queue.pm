package AmuseWikiFarm::Utils::Queue;
use utf8;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

use JSON;
use DateTime;

=head2 site

The Schema::Result::Site dbic object.

=cut

has site => (
             isa => 'Object',
             is => 'ro',
             required => 1,
            );

sub add {
    return;
}









__PACKAGE__->meta->make_immutable;

1;
