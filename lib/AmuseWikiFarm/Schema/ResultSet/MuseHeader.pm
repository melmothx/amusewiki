package AmuseWikiFarm::Schema::ResultSet::MuseHeader;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use AmuseWikiFarm::Log::Contextual;
use DateTime;

sub by_name {
    my ($self, $name) = @_;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.muse_header" => $name });
}

sub header_value_by_name {
    my ($self, $name) = @_;
    my $rs = $self->by_name($name);
    # be sure we are not pulling from all texts
    my $count = $rs->count;
    if ($count == 1) {
        return $rs->first->muse_value;
    }
    elsif ($count == 0) {
        return undef;
    }
    else {
        log_error { "Called header_value_by_name and got $count results" };
        return undef;
    }
}

1;
