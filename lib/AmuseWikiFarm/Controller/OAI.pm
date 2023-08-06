package AmuseWikiFarm::Controller::OAI;
use Moose;

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;

=head1 NAME

AmuseWikiFarm::Controller::OaiPmh - Catalyst Controller implementing OAI-PMH protocol

=head1 DESCRIPTION

See L<https://www.openarchives.org/OAI/openarchivesprotocol.html>

=head1 METHODS

=cut


=head2 root

There is a single entry point.

=cut

sub pmh :Chained('/site') :PathPart('oai-pmh') :Args(0) {
    my ($self, $c) = @_;
    my $params = $c->request->params;
    my $xml = $c->model('OaiPmh')->process_request($params);
    # 3.1.2.1
    $c->response->content_type('text/xml');
    $c->response->body($xml);
    # compression is handled by the frontend server
}

=encoding utf8

=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
