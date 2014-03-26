package AmuseWikiFarm::Controller::Edit;
use strict;
use warnings;
use utf8;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Edit - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 /new

Chained action for creation of new texts

=head3 create

Root chain element.

=head3 render_created

Path: /new

The only purpose of this path is to present a form, which will post to


=head3 add_created

Path: /new/add



=cut

sub create :Chained('') :PathPart('new') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash(template => 'edit/create.tt');
    $c->stash(form_action => $c->uri_for_action('edit/add_created'));
    my %available_languages = (
                               ru => 'Русский',
                               sr => 'Srpski',
                               hr => 'Hrvatski',
                               mk => 'Македонски',
                               fi => 'Suomi',
                               es => 'Español',
                               en => 'English',
                              );
    $c->stash(known_langs => \%available_languages);
}

sub render_created :Chained('create') :PathPart('') :Args(0) {

}

sub add_created :Chained('create') :PathPart('add') :Args(0) {

}


sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched AmuseWikiFarm::Controller::Edit in Edit.');
}


=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
