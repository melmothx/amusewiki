package AmuseWikiFarm::Schema::ResultSet::Attachment;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';


=head2 by_uri

Find an attachment by uri

=cut

sub by_uri {
    my ($self, $uri) = shift;
    return $self->single({ uri => $uri });
}


1;

