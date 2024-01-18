package AmuseWikiFarm::Schema::ResultSet::Annotation;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

__PACKAGE__->load_components('Helper::ResultSet::Shortcut::HRI');


sub active_only {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.active" => 1 });
}

sub public_only {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.private" => 0 });
}

sub sorted {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search(undef, { order_by => "$me.priority" });
}

sub as_hashref_list {
    my $self = shift;
    my $me = $self->current_source_alias;
    my @all = map { +{
                      label => $_->label,
                      name => $_->annotation_name,
                      id => $_->annotation_id,
                      type => $_->annotation_type,
                      private => $_->private,
                     }
                } $self->all;
    return @all;
}

1;
