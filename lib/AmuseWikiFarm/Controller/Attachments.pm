package AmuseWikiFarm::Controller::Attachments;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Utils::Paginator;


=head1 NAME

AmuseWikiFarm::Controller::Attachments - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub root :Chained('/site_user_required') :PathPart('attachments') :CaptureArgs(0) {
    my ($self, $c) = @_;
    die "Shouldn't happen" unless $c->user_exists;
    my $site = $c->stash->{site};
    my $attachments = $site->attachments;
    my $name = $c->loc('Attachments');
    $c->stash(full_page_no_side_columns => 1,
              attachments => $attachments,
              page_title => $name,
              breadcrumbs => [
                              {
                               uri => $c->uri_for_action('/attachments/list'),
                               label => $name,
                              }
                             ],
             );
}

sub orphans :Chained('root') :Args(0) {
    my ($self, $c, $page) = @_;
    my @list;
    my $site = $c->stash->{site};
    my $all = $c->stash->{attachments}->public_only->orphans;
    while (my $att = $all->next) {
        my $ainfo = {
                     id => $att->id,
                     full_uri => $c->uri_for($att->full_uri),
                     name => $att->uri,
                     thumb => $c->uri_for($att->small_uri),
                     has_thumbnails => $att->has_thumbnails,
                     errors => $att->errors,
                    };
        if ($ainfo->{has_thumbnails}) {
            $ainfo->{has_thumbnails} = 0 unless $att->has_thumbnail_file('small');
        }
        push @list, $ainfo;
    }
    push @{$c->stash->{breadcrumbs}},
      {
       uri => $c->uri_for_action('/attachments/orphans'),
       label => $c->loc('Files not referenced by any text'),
      };
    $c->stash(attachments_list => \@list);
}

sub prune :Chained('root') :Args(0) {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};
    if (my $removals = $c->request->body_params->{prune}) {
        my $job = $site->jobs->enqueue(prune_orphans => {
                                                         prune => ref($removals) ? $removals : [ $removals ],
                                                        }, $c->user->get('username'));
        $c->res->redirect($c->uri_for_action('/tasks/display',
                                             [$job->id]));
    }
    else {
        $c->response->redirect($c->uri_for_action('/attachments/orphans'));
    }
}

sub list :Chained('root') :Args {
    my ($self, $c, $page) = @_;
    my @list;
    my $site = $c->stash->{site};
    my $all = $c->stash->{attachments}->public_only->search(undef, { order_by => 'uri' });
    while (my $att = $all->next) {
        my $ainfo = {
                     full_uri => $c->uri_for($att->full_uri),
                     name => $att->uri,
                     thumb => $c->uri_for($att->small_uri),
                     title => $att->title_html,
                     desc => $att->comment_html,
                     has_thumbnails => $att->has_thumbnails,
                     alt_text => $att->alt_text,
                     errors => $att->errors,
                    };
        if ($ainfo->{has_thumbnails}) {
            $ainfo->{has_thumbnails} = 0 unless $att->has_thumbnail_file('small');
        }
        push @list, $ainfo;

    }
    $c->stash(attachments_list => \@list,
              load_datatables => 1,
             );
}

sub attachment :Chained('root') :PathPart('show') :CaptureArgs(1) {
    my ($self, $c, $uri) = @_;
    if (my $att = $c->stash->{attachments}->by_uri($uri)) {
        $c->stash(attachment => $att);
    }
    else {
        $c->detach('/not_found');
    }
}

sub edit :Chained('attachment') :Args(0) {
    my ($self, $c) = @_;
    my $att = $c->stash->{attachment};
    my $uri = $att->uri;
    my $params = $c->request->body_params;
    if ($params->{update}) {
        $att->edit(
                   title_muse => $params->{title_muse},
                   comment_muse => $params->{desc_muse},
                   alt_text => $params->{alt_text},
                  );
        $c->flash(status_msg => $c->loc('The description for [_1] has been updated', $uri));
    }

    push @{$c->stash->{breadcrumbs}},
      {
       uri => $c->uri_for_action('/attachments/edit', $uri),
       label => $uri,
      };
    $c->stash(page_title => $att->uri,
              load_markitup_css => 1,
             );
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
