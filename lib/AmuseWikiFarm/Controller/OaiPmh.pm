package AmuseWikiFarm::Controller::OaiPmh;
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

sub root :Chained('/site') :PathPart('oai-pmh') :Args(0) {
    my ($self, $c) = @_;
    my $oaipmh = $c->model('OaiPmh');
    log_debug { "Base url is " . $oaipmh->oai_pmh_url };
    $c->res->body('OK');
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
