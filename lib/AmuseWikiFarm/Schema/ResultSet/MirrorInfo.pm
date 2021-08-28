package AmuseWikiFarm::Schema::ResultSet::MirrorInfo;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use DateTime;
use AmuseWikiFarm::Log::Contextual;

=head1 NAME

AmuseWikiFarm::Schema::ResultSet::MirrorInfo - MirrorInfo resultset

=cut

sub download_completed {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ download_destination => { '!=' => '' } });
}

1;
