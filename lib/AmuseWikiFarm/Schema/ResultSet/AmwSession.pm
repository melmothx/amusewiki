package AmuseWikiFarm::Schema::ResultSet::AmwSession;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use AmuseWikiFarm::Utils::Amuse ();
use AmuseWikiFarm::Log::Contextual;

sub get_session_data {
    my ($self, $sid) = @_;
    log_debug { "Calling get_session_data for $sid" };
    if (my $sx = $self->find({ session_id => $sid })) {
        return AmuseWikiFarm::Utils::Amuse::from_json($sx->session_data)->[0];
    }
    else {
        return;
    }
}
sub store_session_data {
    my ($self, $sid, $data) = @_;
    Dlog_debug { "Calling store_session_data for $sid $_" } $data;
    $self->update_or_create({
                             session_id => $sid,
                             session_data => AmuseWikiFarm::Utils::Amuse::to_json([ $data ]),
                            });
    return;
}
sub delete_session_data {
    my ($self, $sid) = @_;
    log_debug { "Calling delete_session_data for $sid" };
    $self->search({ session_id => $sid })->delete;
    return;
}

sub delete_expired_sessions {
    my $self = @_;
    log_debug { "Calling delete_expired_sessions" };
    return;
}



1;
