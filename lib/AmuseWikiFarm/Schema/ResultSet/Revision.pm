package AmuseWikiFarm::Schema::ResultSet::Revision;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use AmuseWikiFarm::Log::Contextual;
use DateTime;

=head1 NAME

AmuseWikiFarm::Schema::ResultSet::Revision - Revision resultset

=head1 METHODS

=head2 pending

Return a resultset of pending revisions, sorted by update date
descending.

=cut

sub sort_by_updated_desc {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search(undef,
                         { order_by => [
                                        { -desc => "$me.updated" },
                                        { -asc => "$me.id" }
                                       ] });
}

sub pending {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->sort_by_updated_desc->search({ "$me.status" => 'pending' });
}

=head2 not_published

Return a resultset of revisions not yet published, sorted by update
date, descending.

=cut

sub not_published {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->sort_by_updated_desc->search({ "$me.status" => { '!=' => 'published'  } });
}


=head2 published_older_than($datetime)

Return the resultset for the published revision older than the
datetime object passed as argument.

=cut

sub published_older_than {
    my ($self, $time) = @_;
    die unless $time && $time->isa('DateTime');
    my $format_time = $self->result_source->schema->storage->datetime_parser
      ->format_datetime($time);
    my $me = $self->current_source_alias;
    return $self->search({
                          "$me.status" => 'published',
                          "$me.updated" => { '<' => $format_time },
                         });
}

=head2 purge_old_revisions

Find the published revisions older than a month and call C<delete> on
each of them to have the associated files purged correctly.

=cut

sub purge_old_revisions {
    my $self = shift;
    my $reftime = DateTime->now;
    # after one month, delete the revisions and jobs
    $reftime->subtract(months => 1);
    my $old_revs = $self->published_older_than($reftime);
    while (my $rev = $old_revs->next) {
        die unless $rev->status eq 'published'; # this shouldn't happen
        log_info { "Removing published revision " . $rev->id . " for site " .
                     $rev->site->id . " and title " . $rev->title->uri };
        $rev->delete;
    }
}

=head2 as_list

Return an arrayref of the revisions, leaving the uncommitted texts at
the end.

=cut

sub as_list {
    my $self = shift;
    my (@top, @bottom);
    while (my $rev = $self->next) {
        if ($rev->status && $rev->status eq 'pending') {
            push @top, $rev;
        }
        else {
            push @bottom, $rev;
        }
    }
    return [ @top, @bottom ];
}

1;
