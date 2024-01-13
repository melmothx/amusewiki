package AmuseWikiFarm::Schema::ResultSet::Aggregation;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

__PACKAGE__->load_components('Helper::ResultSet::Shortcut::HRI');

sub with_title_uri {
    my ($self, $uri) = @_;
    my $me = $self->current_source_alias;
    $self->search({
                   'aggregation_titles.title_uri' => $uri,
                  },
                  {
                   join => [qw/aggregation_titles/],
                   '+select' => [
                                 "aggregation_titles.sorting_pos",
                                ],
                   '+as' => [
                             "$me.title_sorting_pos",
                            ],
                  });
}

sub no_match {
    my $self = shift;
    my $me = $self->current_source_alias;
    $self->search({ "$me.aggregation_id" => [] });
}

sub sorted {
    my $self = shift;
    my $me = $self->current_source_alias;
    $self->search(undef,
                  {
                   order_by => [ "$me.aggregation_code", "$me.sorting_pos", "$me.aggregation_uri" ],
                  })
}

1;
