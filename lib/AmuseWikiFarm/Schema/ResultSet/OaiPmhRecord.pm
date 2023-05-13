package AmuseWikiFarm::Schema::ResultSet::OaiPmhRecord;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use AmuseWikiFarm::Log::Contextual;

sub in_range {
    my ($self, $from, $until) = @_;
    my $dtf = $self->result_source->schema->storage->datetime_parser;
    my $me = $self->current_source_alias;
    my %search;
    if ($from) {
        $search{'>='} = $dtf->format_datetime($from);
    }
    if ($until) {
        $search{'<='} = $dtf->format_datetime($until);
    }
    if (%search) {
        return $self->search({ datestamp => \%search });
    }
    else {
        return $self;
    }
}


1;
