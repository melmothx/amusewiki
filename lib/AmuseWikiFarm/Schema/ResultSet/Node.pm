package AmuseWikiFarm::Schema::ResultSet::Node;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use HTML::Entities qw/encode_entities/;

sub hri {
    return shift->search(undef, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' });
}

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

sub sorted {
    my $self = shift;
    my $me = $self->current_source_alias;
    $self->search(undef, { order_by => [map { $me . '.' . $_ } (qw/sorting_pos uri/) ] });
}

sub with_body {
    my ($self, $lang) = @_;
    my $me = $self->current_source_alias;
    $self->search({
                   'node_bodies.lang' => [ $lang || 'en', undef ],
                  },
                  {
                   prefetch => 'node_bodies',
                  });
}

sub all_nodes {
    my ($self, $lang) = @_;
    my $me = $self->current_source_alias;
    my @all = $self->search(undef, { order_by => "$me.uri" })->with_body->hri;
    my @out;
    foreach my $node (@all) {
        my %node = (
                    value => $node->{node_id},
                    title => join('/', '', 'node', $node->{full_path}),
                    label => encode_entities($node->{uri}),
                   );
        if (@{$node->{node_bodies}}) {
            if (my $label = $node->{node_bodies}->[0]->{title_html}) {
                $node{label} = $label;
            }
        }
        push @out, \%node;
    }
    return \@out;
}


1;
