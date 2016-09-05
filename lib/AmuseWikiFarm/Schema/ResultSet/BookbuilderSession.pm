package AmuseWikiFarm::Schema::ResultSet::BookbuilderSession;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head1 NAME

AmuseWikiFarm::Schema::ResultSet::BookbuilderSession - bookbuilder sessions resultset

=head1 METHODS

=head2 from_token($token)

Return a row from bookbuilder_session matching the token passed as argument.

The token is composed by token, a dash, and the bookbuilder_session_id

Return undef if the row doesn't exist.

=cut

sub from_token {
    my ($self, $token) = @_;
    return unless $token;
    if ($token =~ m/([0-9A-Z]+)-([0-9]+)/) {
        my $tk = $1;
        my $id = $2;
        my $me = $self->current_source_alias;
        return $self->single({
                              "$me.bookbuilder_session_id" => $id,
                              "$me.token" => $tk,
                             });
    }
    return;
}


1;
