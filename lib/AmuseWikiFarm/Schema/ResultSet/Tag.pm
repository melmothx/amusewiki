package AmuseWikiFarm::Schema::ResultSet::Tag;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub find_by_uri {
    my ($self, $uri) = @_;
    my $me = $self->current_source_alias;
    return $self->find({ "$me.uri" => $uri });
}

1;
