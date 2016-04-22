package AmuseWikiFarm::Controller::Help;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;

=head1 NAME

AmuseWikiFarm::Controller::Help - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 root

Does nothing, so far

=head2 opds

Render the template help/opds.tt

=cut

sub root :Chained('/site') :PathPart('help') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub opds :Chained('root') :PathPart('opds') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(page_title => $c->loc('[_1] on mobile', $c->stash->{site}->full_name));
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
