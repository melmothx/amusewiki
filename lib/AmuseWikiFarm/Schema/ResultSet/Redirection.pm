package AmuseWikiFarm::Schema::ResultSet::Redirection;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub by_uri {
    my ($self, $uri) = @_;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.uri" => $uri });
}

1;
