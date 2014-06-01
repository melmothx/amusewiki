package AmuseWikiFarm::Controller::Admin;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Admin - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 auto

Grant access to root users only.

=cut

sub auto :Private {
    my ($self, $c) = @_;
    if ($c->user_exists && $c->check_user_roles('root')) {
        return 1;
    }
    else {
        $c->detach('/not_permitted');
        return;
    }
}

=head2 debug_site_id

Show the site id.

=cut

sub debug_site_id :Local :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body(join(" ",
                            $c->stash->{site}->id,
                            $c->stash->{site}->locale,
                           ));
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
