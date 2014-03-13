package AmuseWikiFarm::Schema::ResultSet::Title;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

__PACKAGE__->load_components('Helper::ResultSet::Random');

=head2 published_texts

List the published titles (deleted set to empty string and publication
date in the past.

=cut

sub published_texts {
    my $self = shift;
    return $self->search({
                          status => 'published',
                         },
                         { order_by => [qw/sorting_pos
                                           title/]
                         });

}

=head2 random_text

Get a random row

=cut

sub random_text {
    my $self = shift;
    return $self->published_texts->rand->single;
}


=head2 by_uri

Find a published text by uri

=cut

sub by_uri {
    my ($self, $uri) = @_;
    return $self->published_texts->single({ uri => $uri });
}


1;

