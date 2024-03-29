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

sub not_deleted {
    my $self = shift;
    my $me = $self->current_source_alias;
    $self->search({ "$me.deleted" => 0 });
}

sub set_deleted_flag_on_obsolete_records {
    my ($self, $ids) = @_;
    die "Missing ids" unless $ids && ref($ids) eq 'ARRAY';
    my $now = time();
    my $dt = $self->result_source->schema->storage->datetime_parser
      ->format_datetime(DateTime->from_epoch(epoch => $now, time_zone => 'UTC'));
    my $me = $self->current_source_alias;
    $self->search({
                   "$me.oai_pmh_record_id" => { -in => $ids },
                  })->update({
                              deleted => 1,
                              datestamp => $dt,
                              update_run => $now,
                             });
}

sub bump_datestamp {
    my ($self) = @_;
    my $dt = $self->result_source->schema->storage->datetime_parser
      ->format_datetime(DateTime->now(time_zone => 'UTC'));
    $self->update({ datestamp => $dt });
}

sub by_title_id {
    my ($self, $ids) = @_;
    my $me = $self->current_source_alias;
    $self->search({ "$me.title_id" => { -in => $ids } });
}

sub by_id {
    my ($self, $ids) = @_;
    my $me = $self->current_source_alias;
    $self->search({ "$me.oai_pmh_record_id" => { -in => $ids } });
}

sub landing_pages_only {
    my ($self, $ids) = @_;
    my $me = $self->current_source_alias;
    # a dot in the path means that's a file format
    $self->search({ "$me.identifier" => { -not_like => '%.%' } });
}

1;
