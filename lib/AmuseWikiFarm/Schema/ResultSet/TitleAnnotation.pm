package AmuseWikiFarm::Schema::ResultSet::TitleAnnotation;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub public {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({
                          "annotation.private" => 0,
                          "annotation.active" => 1,
                         },
                         {
                          prefetch => [qw/annotation/],
                         });
}

sub active {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({
                          "annotation.active" => 1,
                         },
                         {
                          prefetch => [qw/annotation/],
                         });
}

sub by_type {
    my ($self, $type) = @_;
    my $me = $self->current_source_alias;
    return $self->search({
                          "annotation.annotation_type" => $type,
                         },
                         {
                          prefetch => [qw/annotation/],
                         });
}

1;
