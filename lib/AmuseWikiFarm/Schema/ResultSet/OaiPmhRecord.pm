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
        return $self->search({ "$me.datestamp" => \%search });
    }
    else {
        return $self;
    }
}

sub sorted_for_oai_list {
    my ($self) = @_;
    my $me = $self->current_source_alias;
    return $self->search(undef, { order_by => { -asc => "$me.datestamp" } });
}

sub oldest_record {
    my $self = shift;
    my $me = $self->current_source_alias;
    $self->search(undef,
                  {
                   order_by => { -asc => "$me.datestamp" },
                   rows => 1,
                  })->first;
}

sub set_deleted_flag_on_obsolete_records {
    my ($self, $last_run) = @_;
    die "Missing epoch argument" unless $last_run;
    my $dt = $self->result_source->schema->storage->datetime_parser
      ->format_datetime(DateTime->now(time_zone => 'UTC'));
    my $me = $self->current_source_alias;
    $self->search({
                   "$me.deleted" => 0,
                   "$me.update_run" => { '!=' => $last_run },
                  })->update({
                              deleted => 1,
                              datestamp => $dt,
                             });
}

1;
