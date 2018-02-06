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
    die "Missing session name" unless $string;
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
    my ($self, $site_id, $string) = @_;
    die "Required arguments site_id and session_id missing" unless $site_id && $string;
    my ($session_id, $field) = _split_id_and_field($string);
    if (my $sx = $self->single({
                              session_id => $session_id,
                              site_id => $site_id,
                             })) {
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
    my ($self, $site_id, $string, $data) = @_;
    die "Required arguments site_id and session_id missing" unless $site_id && $string;
    my ($session_id, $field) = _split_id_and_field($string);
    Dlog_debug { "Calling store_session_data for $session_id $_" } $data;
    my $serialized;
    if ($field eq 'expires') {
        if ($data =~ m/\A[1-9][0-9]+\z/) {
            $serialized = $data;
        }
        else {
            Dlog_error { "expires is supposed to be an integer, got $_, nulling out" } $data;
            $serialized = undef;
        }
    }
    else {
        $serialized = encode_json([ $data ]);
    }
    $self->update_or_create({
                             site_id => $site_id,
                             session_id => $session_id,
                             $field => $serialized,
                            });
    return;
}
sub delete_session_data {
    my ($self, $site_id, $string) = @_;
    die "Required arguments site_id and session_id missing" unless $site_id && $string;
    my ($session_id, $field) = _split_id_and_field($string);
    log_debug { "Calling delete_session_data for $session_id" };
    if (my $sx = $self->single({
                                session_id => $session_id,
                                site_id => $site_id,
                               })) {
        $sx->$field(undef);
        if ($sx->expires || $sx->session_data || $sx->flash_data || $sx->generic_data) {
            $sx->update;
        }
        else {
            $sx->delete;
        }
    }
    else {
        log_debug { "$session_id to delete not found!" };
    }
    return;
}

sub delete_expired_sessions {
    my ($self, $site_id) = @_;
    my $now = time();
    log_debug { "Calling delete_expired_sessions" };
    my $rs = $self->search(
                           {
                            expires => { '<' => $now },
                            ($site_id ? (site_id => $site_id) : ()), # optional
                           }
                          );
    log_info { "Nuking " . $rs->count . " expired sessions" };
    $rs->delete;
    return;
}

1;
