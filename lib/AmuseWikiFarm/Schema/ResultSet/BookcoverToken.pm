package AmuseWikiFarm::Schema::ResultSet::BookcoverToken;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub sorted {
    my $self = shift;
    my $me = $self->current_source_alias;
    $self->search(undef, { order_by => [ "$me.sorting_pos", "$me.token_name" ] });
}


1;
