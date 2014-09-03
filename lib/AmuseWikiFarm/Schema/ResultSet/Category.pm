package AmuseWikiFarm::Schema::ResultSet::Category;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head2 by_type($type)

Return the sorted categories of a given type

=cut

sub by_type {
    my ($self, $type) = @_;
    return $self->search({ type => $type },
                         { order_by => [qw/sorting_pos
                                           name/] });
}

=head2 active_only_by_type($type)

Return the sorted categories of a given type (C<author> or C<topic>)
which have a text count greater than 0.

=cut

sub active_only_by_type {
    my ($self, $type) = @_;
    return $self->search({
                          type => $type,
                          text_count => { '>' => 0 },
                         },
                         {
                          order_by => [qw/sorting_pos name/],
                         });
}

=head2 by_type_and_uri($type, $uri)

Return the category which corresponds to type and uri

=cut


sub by_type_and_uri {
    my ($self, $type, $uri) = @_;
    return $self->single({type => $type,
                          uri  => $uri});
}

1;

