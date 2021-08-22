package AmuseWikiFarm::Schema::ResultSet::BulkJob;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use AmuseWikiFarm::Log::Contextual;

sub rebuilds {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.task" => 'rebuild' });
}

sub reindexes {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.task" => 'reindex' });
}

sub mirrors {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.task" => 'mirror' });
}


sub active_bulk_jobs {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.completed" => undef },
                         { order_by => { -desc => "$me.created" } });
}

sub completed_jobs {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.status" => 'completed' },
                         { order_by => { -desc => "$me.completed" } });
}

sub abort_all {
    my $self = shift;
    while (my $job = $self->next) {
        log_info { "Aborting bulk jobs for " . $job->site->canonical };
        $job->abort_jobs;
    }
}

1;
