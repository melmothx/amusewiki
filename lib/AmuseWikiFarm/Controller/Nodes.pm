package AmuseWikiFarm::Controller::Nodes;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Nodes - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

use AmuseWikiFarm::Log::Contextual;

sub root :Chained('/site') :PathPart('nodes') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub display :Chained('root') :PathPart('') :Args() {
    my ($self, $c, @args) = @_;

    # The uri part is unique, so in theory we could just look at the
    # last piece. We don't look at what's in between. We could just
    # ignore the pieces in between, or validate the whole path,
    # comparing the path requested with the real path, or redirect if
    # doesn't match. Going for this last option.
    $c->detach('/not_found') unless @args;
    log_debug { "Displaying " . join("/", @args) };
    if (my $target = $c->stash->{site}->nodes->find_by_uri($args[-1])) {
        my $full_uri = $target->full_uri;
        my $got = join('/', '', nodes => @args);
        log_debug { "$full_uri and $got" };
        if ($full_uri ne $got) {
            $c->response->redirect($c->uri_for($full_uri), 301);
            $c->detach();
            return;
        }
    }
    else {
        log_info { $args[-1] . ' not found'};
        $c->detach('/not_found');
    }
}

sub admin :Chained('/site_user_required') :PathPart('node-editor') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub list_nodes :Chained('admin') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    if (my $uri = $c->request->body_parameters->{uri}) {
        log_info { $c->user->get('username') . " is creating nodes/$uri" };
        $c->stash->{site}->nodes->find_or_create({ uri => $uri });
        $c->response->redirect($c->uri_for_action('/nodes/edit_node', [$uri]));
    }
}

sub edit :Chained('admin') :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $uri) = @_;
    if (my $node = $c->stash->{site}->nodes->find_by_uri($uri)) {
        $c->stash(edit_node => $node);
    }
    else {
        $c->detach('/not_found');
    }
}

sub delete_node :Chained('edit') :PathPart('delete') :Args(0) {
    my ($self, $c) = @_;
    my $node = $c->stash->{edit_node};
    if ($c->request->body_parameters->{delete}) {
        log_info { $c->user->get('username') . " is deleting " . $node->full_uri };
        $node->delete;
    }
    $c->response->redirect($c->uri_for_action('/nodes/list_nodes'));
}

sub update_node :Chained('edit') :PathPart('update') :Args(0) {
    my ($self, $c) = @_;
    my $node = $c->stash->{edit_node};
    my %params = %{ $c->request->body_parameters };
    if (%params and $params{update}) {
        Dlog_info { $c->user->get('username') . " is updating " . $node->full_uri . " with $_" } \%params;
        $node->update_from_params(\%params);
        $c->stash({ update_ok => 1 });
    }
}


=encoding utf8

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
