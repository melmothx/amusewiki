package AmuseWikiFarm::Schema::ResultSet::AggregationTitle;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

__PACKAGE__->load_components('Helper::ResultSet::Shortcut::HRI');

sub by_title_uri {
    my ($self, $uri) = @_;
    my $me = $self->current_source_alias;
    $self->search({ "$me.title_uri" => $uri });
}

1;
