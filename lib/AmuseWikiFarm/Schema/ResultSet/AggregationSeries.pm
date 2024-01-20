package AmuseWikiFarm::Schema::ResultSet::AggregationSeries;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

__PACKAGE__->load_components('Helper::ResultSet::Shortcut::HRI');

sub sorted {
    my $self = shift;
    my $me = $self->current_source_alias;
    $self->search(undef, { order_by => "$me.aggregation_series_name" });
}

sub by_uri {
    my ($self, $uri) = @_;
    my $me = $self->current_source_alias;
    $self->search({ "$me.aggregation_series_uri" => $uri });
}

sub by_full_uri {
    my ($self, $full_uri) = @_;
    if ($full_uri =~ m{series\/([a-z0-9-]+)\s*\z}) {
        return $self->by_uri($1)->single;
    }
    return;
}

1;
