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

sub hri {
    my $self = shift;
    return $self->search(undef, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' });
}

sub download_completed {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.download_destination" => { '!=' => '' } });
}

sub with_exceptions {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.mirror_exception" => { '!=' => '' } });
}

1;
