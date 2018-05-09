package AmuseWikiMeta::Controller::Root;
use Moose;

use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller' }

use AmuseWikiFarm::Log::Contextual;


#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

sub root :Chained('/') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub home :Chained('root') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{json}->{sites} = [ map { $_->id } $c->model('DB::Site')->search({ mode => { '!=' => 'private' } }) ];
}

sub end : ActionClass('RenderView') {
    my ($self, $c) = @_;
}

__PACKAGE__->meta->make_immutable;

1;
