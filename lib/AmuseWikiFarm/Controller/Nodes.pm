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
use HTML::Entities qw/encode_entities/;

sub root :Chained('/site') :PathPart('node') :CaptureArgs(0) {
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
        my $got = join('/', '', node => @args);
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
    my $site = $c->stash->{site};
    $c->stash(breadcrumbs => [{
                               uri => $c->uri_for_action('/nodes/list_nodes'),
                               label => $c->loc('Nodes'),
                              }]);
    $c->stash(all_nodes => [ $site->nodes->all ]);
}

sub list_nodes :Chained('admin') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};
    my %params = %{$c->request->body_parameters};
    if (my $uri = $params{uri}) {
        log_info { $c->user->get('username') . " is creating nodes/$uri" };
        if (my $node = $site->nodes->update_or_create_from_params(\%params)) {
            $c->response->redirect($c->uri_for_action('/nodes/update_node', [$node->uri]));
        }
        else {
            log_error { "Failed attempt to create " . $site->id . "/node/$uri" };
        }
    }
    $c->stash(nodes => [ $site->nodes->root_nodes->all ]);
}

sub edit :Chained('admin') :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $uri) = @_;
    if (my $node = $c->stash->{site}->nodes->find_by_uri($uri)) {
        $c->stash(edit_node => $node);
        push @{$c->stash->{breadcrumbs}}, {
                                           uri => $c->uri_for_action('/nodes/update_node', [$node->uri]),
                                           label => encode_entities($node->uri),
                                          };
    }
    else {
        $c->detach('/not_found');
    }
}

sub delete_node :Chained('edit') :PathPart('delete') :Args(0) {
    my ($self, $c) = @_;
    my $node = $c->stash->{edit_node};
    # ok, I know, just visiting an url shouldn't trigger a deletion.
    # This is TODO when the code has stabilized.
    log_info { $c->user->get('username') . " is deleting " . $node->full_uri };
    $node->delete;
    $c->response->redirect($c->uri_for_action('/nodes/list_nodes'));
}

sub update_node :Chained('edit') :PathPart('edit') :Args(0) {
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
