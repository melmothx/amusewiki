package AmuseWikiFarm::Schema::ResultSet::AmwSession;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use AmuseWikiFarm::Log::Contextual;
use JSON::MaybeXS;

my %FIELDS = (
              session => 'session_data',
              expires => 'expires',
              flash => 'flash_data',
             );


sub _split_id_and_field {
    my $string = shift;
    my ($field, $sid) = split(/:/, $string, 2);
    if (my $dbfield = $FIELDS{$field}) {
        return ($sid, $dbfield);
    }
    else {
        log_warn { "$string is not parsable, using generic_data" };
        return ($string, "generic_data");
    }
}

sub get_session_data {
    my ($self, $string) = @_;
    my ($sid, $field) = _split_id_and_field($string);
    log_debug { "Calling get_session_data $field for $sid" };
    if (my $sx = $self->find({ session_id => $sid })) {
        if ($field eq 'expires') {
            return $sx->expires;
        }
        else {
            return decode_json($sx->$field)->[0];
        }
    }
    else {
        return;
    }
}
sub store_session_data {
    my ($self, $string, $data) = @_;
    my ($sid, $field) = _split_id_and_field($string);
    Dlog_debug { "Calling store_session_data for $sid $_" } $data;
    $self->update_or_create({
                             session_id => $sid,
                             $field => ($field eq 'expires' ? $data : encode_json([ $data ])),
                            });
    return;
}
sub delete_session_data {
    my ($self, $string) = @_;
    my ($sid, $field) = _split_id_and_field($string);
    log_debug { "Calling delete_session_data for $sid" };
    if (my $sx = $self->find({ session_id => $sid })) {
        $sx->$field(undef);
        if ($sx->expires || $sx->session_data || $sx->flash_data || $sx->generic_data) {
            $sx->update;
        }
        else {
            $sx->delete;
        }
    }
    else {
        log_debug { "$sid not found!" };
    }
    return;
}

sub delete_expired_sessions {
    my ($self) = @_;
    my $now = time();
    log_debug { "Calling delete_expired_sessions" };
    my $rs = $self->search({ expires => { '<' => $now } });
    log_info { "Nuking " . $rs->count . " expired sessions" };
    $rs->delete;
    return;
}

1;
