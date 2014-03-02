package AmuseWikiFarm::Schema::ResultSet::Title;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';


=head2 published_texts

List the published titles

=cut

sub published_texts {
    my $self = shift;
    return $self->search({ deleted => '' }, { order_by => [qw/sorting_pos
                                                              title/] });

}

=head2 by_uri

Find a text by uri

=cut

sub by_uri {
    my ($self, $uri) = @_;
    return $self->single({ deleted => '',
                           uri => $uri });
}


1;

