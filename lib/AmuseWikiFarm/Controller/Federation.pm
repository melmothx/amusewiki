package AmuseWikiFarm::Controller::Federation;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;
use Data::Dumper::Concise;

=head1 NAME

AmuseWikiFarm::Controller::Federation - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub root :Chained('/site_user_required') :PathPart('federation') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub sources :Chained('root') :PathPart('sources') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $rs = $c->stash->{site}->mirror_origins;
    $c->stash(origins_rs => $rs);
}

sub show :Chained('sources') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    my $origins = [ $c->stash->{origins_rs}->hri->all ];
    $c->stash(origins => $origins);
    Dlog_debug { "Origins: $_" } $origins;
    $c->response->body("OK");
}

sub details :Chained('sources') :PathPart('') :Args(1) {
    my ($self, $c, $id) = @_;
    if (my $origin = $c->stash->{origins_rs}->find($id)) {
        my @exceptions = $origin->mirror_infos->with_exceptions->all;
        Dlog_debug { "Exceptions are $_"  } \@exceptions;
        $c->stash(
                  mirror_exceptions => \@exceptions,
                  mirror_origin => { $origin->get_columns }
                 );
        $c->response->body("OK");
    }
    else {
        $c->detach('/not_found');        
    }
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
