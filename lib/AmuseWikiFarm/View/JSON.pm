package AmuseWikiFarm::View::JSON;
use strict;
use warnings;

use base qw( Catalyst::View::JSON );
use AmuseWikiFarm::Utils::Amuse ();
use AmuseWikiFarm::Log::Contextual;

__PACKAGE__->config(expose_stash => 'json');

sub encode_json {
    my($self, $c, $data) = @_;
    Dlog_debug { "Serializing $_" } $data;
    my $json = AmuseWikiFarm::Utils::Amuse::to_json($data);
    if (defined $json) {
        log_debug { "JSON is $json" }; 
        return $json;
    }
    else {
        Dlog_error { "json encoding failed for $_" } $data;
        return '';
    }
}
 
1;

=head1 NAME

AmuseWikiFarm::View::JSON - JSON View for AmuseWikiFarm

=head1 DESCRIPTION

JSON View for AmuseWikiFarm. Serialize the "json" key of the stash.

=head1 SEE ALSO

L<AmuseWikiFarm>

=head1 AUTHOR

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
