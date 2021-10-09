package AmuseWikiFarm::Schema::ResultSet::MirrorOrigin;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use DateTime;
use AmuseWikiFarm::Log::Contextual;

=head1 NAME

AmuseWikiFarm::Schema::ResultSet::MirrorOrigin - MirrorOrigin resultset

=cut

sub hri {
    my $self = shift;
    return $self->search(undef, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' });
}

1;
