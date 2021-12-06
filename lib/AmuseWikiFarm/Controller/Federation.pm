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
    unless ($c->check_any_user_role(qw/admin root/)) {
        $c->detach('/not_permitted');
        return;
    }
}

sub sources :Chained('root') :PathPart('sources') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $rs = $c->stash->{site}->mirror_origins;
    $c->stash(origins_rs => $rs);
}

sub show :Chained('sources') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    my $origins = [ $c->stash->{origins_rs}->all ];
    $c->stash(origins => $origins);
    # Dlog_debug { "Origins: $_" } $origins;
}

sub edit :Chained('sources') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;
    my %params = %{ $c->request->body_parameters };
    Dlog_debug { "Params: $_" } \%params;
    my $rs = $c->stash->{origins_rs};
    if ($params{create} && $params{remote_domain} && $params{remote_path}) {
        $rs->create({
                     remote_domain => $params{remote_domain},
                     remote_path => $params{remote_path},
                    });
        $c->res->redirect($c->uri_for_action('/federation/show'));
        return;
    }
    my %out;
    if (my $edit = $params{toggle}) {
        if (my $origin = $rs->find($edit)) {
            $origin->update({ active => $origin->active ? 0 : 1 });
            $out{toggled} = $edit;
        }
        else {
            $out{error} = "$edit not found";
        }
    }
    $c->stash(json => \%out);
    $c->detach($c->view('JSON'));
}

sub details :Chained('sources') :PathPart('details') :Args(1) {
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

sub check :Chained('sources') :PathPart('check') :Args(1) {
    my ($self, $c, $id) = @_;
    my %out;
    if (my $origin = $c->stash->{origins_rs}->find($id)) {
        my $res = $origin->fetch_remote;
        %out = %$res;
    }
    else {
        $out{error} = "Invalid ID $id";
    }
    $c->stash(json => \%out);
    $c->detach($c->view('JSON'));
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
