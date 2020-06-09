package AmuseWikiFarm::Schema::ResultSet::WhitelistIp;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use AmuseWikiFarm::Log::Contextual;

sub editable {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.user_editable" => 1 });
}

1;
