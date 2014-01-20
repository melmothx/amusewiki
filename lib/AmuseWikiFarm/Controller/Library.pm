package AmuseWikiFarm::Controller::Library;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Library - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

List the titles.

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my $id = $c->stash->{site_id};
    my $locale = $c->stash->{locale};
    $c->stash(texts => $c->model('DB::Title')->title_list($id, $locale));
    $c->stash(template => 'list.tt');
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
