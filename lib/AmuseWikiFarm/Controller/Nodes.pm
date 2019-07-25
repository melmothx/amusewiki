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
use HTML::Entities qw/encode_entities decode_entities/;

sub root :Chained('/site') :PathPart('node') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash(please_index => 1);
}

sub node_root :Chained('root') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};
    my $lang = $c->stash->{current_locale_code};
    $c->stash(node_list => $site->nodes->sorted->as_tree($lang),
              page_title => $c->loc('Site Map'),
             );
    if ($c->user_exists) {
        $c->stash(all_nodes => $site->nodes->as_list_with_path($lang));
        Dlog_debug  { "All nodes: $_" } $c->stash->{all_nodes};
    }
}

sub display :Chained('root') :PathPart('') :Args {
    my ($self, $c, @args) = @_;

    # The uri part is unique, so in theory we could just look at the
    # last piece. We don't look at what's in between. We could just
    # ignore the pieces in between, or validate the whole path,
    # comparing the path requested with the real path, or redirect if
    # doesn't match. Going for this last option.
    log_debug { "Displaying " . join("/", @args) };
    my $site = $c->stash->{site};
    if (my $target = $site->nodes->find_by_uri($args[-1])) {
        my $full_uri = $target->full_uri;
        my $got = join('/', '', node => @args);
        log_debug { "$full_uri and $got" };
        if ($full_uri ne $got) {
            $c->response->redirect($c->uri_for($full_uri), 301);
            $c->detach();
            return;
        }
        my $locale = $c->stash->{current_locale_code};
        my $desc = $target->description($locale);
        my $title = $desc ? $desc->title_html : encode_entities($target->uri);
        my $body =  $desc ? $desc->body_html : '';
        my @pages = $target->linked_pages;
        my @children = $target->children_pages(locale => $locale);
        $c->stash(node => $target,
                  node_title => $title,
                  node_body => $body,
                  node_breadcrumbs => [ $target->breadcrumbs($locale) ],
                  node_linked_pages => scalar(@pages) ? \@pages : undef,
                  node_children => scalar(@children) ? \@children : undef,
                  page_title => decode_entities($title), # we need an unescaped one.
                 );
        if ($c->user_exists) {
            $c->stash(edit_node => $target,
                      load_markitup_css => 1,
                      all_nodes => $site->nodes->as_list_with_path($locale),
                     );
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

sub create :Chained('admin') :PathPart('create') :Args(0) {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};
    my %params = %{$c->request->body_parameters};
    if (my $uri = $params{uri}) {
        log_info { $c->user->get('username') . " is creating nodes/$uri" };
        if (my $node = $site->nodes->update_or_create_from_params(\%params)) {
            $c->response->redirect($c->uri_for($node->full_uri));
        }
        else {
            log_error { "Failed attempt to create " . $site->id . "/node/$uri" };
        }
    }
    $c->stash(nodes => [ $site->nodes->root_nodes->sorted->all ]);
}

sub edit :Chained('admin') :PathPart('edit') :CaptureArgs(1) {
    my ($self, $c, $uri) = @_;
    if (my $node = $c->stash->{site}->nodes->find_by_uri($uri)) {
        $c->stash(edit_node => $node);
    }
    else {
        $c->detach('/not_found');
    }
}

sub update_node :Chained('edit') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    my $node = $c->stash->{edit_node};
    my %params = %{ $c->request->body_parameters };
    Dlog_info { "Editing " . $node->node_id . " with $_" } \%params;
    if ($params{update}) {
        Dlog_info { $c->user->get('username') . " is updating " . $node->full_uri . " with $_" } \%params;
        $node->update_from_params(\%params);
        $c->stash({ update_ok => 1 });
    }
    elsif ($params{delete}) {
        Dlog_info { $c->user->get('username') . " deleted $_" } +{ $node->get_columns };
        $node->delete;
        $c->response->redirect($c->uri_for_action('/nodes/node_root'));
        return;
    }
    log_debug { "Redirecting to " . $node->full_uri };
    $c->response->redirect($c->uri_for($node->full_uri));
}


=encoding utf8

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
