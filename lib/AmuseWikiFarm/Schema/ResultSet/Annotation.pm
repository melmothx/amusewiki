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

1;
