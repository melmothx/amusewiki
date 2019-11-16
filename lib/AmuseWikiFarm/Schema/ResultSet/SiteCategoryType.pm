package AmuseWikiFarm::Schema::ResultSet::SiteCategoryType;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use AmuseWikiFarm::Log::Contextual;

sub active {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.active" => 1 });
}

sub ordered {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search(undef, { order_by => 'priority' });
}

1;
