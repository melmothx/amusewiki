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

=head2 latest($number_of_items)

Return the latest published text, ordered by publishing date. If no
argument is provided, return 50 titles (at max).

=cut

sub latest {
    my ($self, $items) = @_;
    $items ||= 50;
    die "Bad usage, a number is required" unless $items =~ m/^[1-9][0-9]*$/s;
    return $self->published_texts->search({}, {
                                               rows => $items,
                                               order_by => { -desc => [qw/pubdate/] },
                                              });
}


1;

