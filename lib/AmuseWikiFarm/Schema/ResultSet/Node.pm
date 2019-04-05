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

sub update_or_create_from_params {
    my ($self, $params) = @_;
    if (my $uri = $params->{uri}) {
        if ($uri =~ m/([a-z0-9][a-z0-9-]*[a-z0-9])/) {
            $uri = $1;
            $uri =~ s/--+/-/g;
            my $node = $self->find_or_create({ uri => $uri });
            $node->discard_changes;
            $node->update_from_params($params);
            return $node;
        }
    }
}

1;
