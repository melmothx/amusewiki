package AmuseWikiFarm::Schema::ResultSet::Node;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub find_by_uri {
    my ($self, $uri) = @_;
    return unless $uri;
    my $me = $self->current_source_alias;
    return $self->find({ "$me.uri" => $uri });
}

sub root_nodes {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.parent_node_id" => undef });
}


1;
