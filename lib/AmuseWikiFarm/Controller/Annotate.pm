package AmuseWikiFarm::Controller::Annotate;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Annotate - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

use AmuseWikiFarm::Log::Contextual;

sub root :Chained('/site_user_required') :PathPart('annotate') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub title :Chained('root') :Args(1) {
    my ($self, $c, $title_id) = @_;
    my $params = $c->req->body_params;
    my $site = $c->stash->{site};
    Dlog_debug { "Params are $_ " } $params;
    if ($title_id and $title_id =~ m/\A\d+\z/a) {
        if (my $title = $site->titles->find($title_id)) {
            # get the uploads
            my %updates;
            foreach my $ann ($site->annotations) {
                my $aid = $ann->annotation_id;
                if ($params->{"passed-$aid"}) {
                    my %single = (value => $params->{"value-$aid"});
                    my ($upload) = $c->request->upload("file-$aid");
                    if ($ann->annotation_type eq 'file' and $upload) {
                        $single{file} = $upload->tempname;
                        $single{value} = $upload->basename;
                    }
                    if ($params->{"wipe-$aid"}) {
                        $single{remove} = 1;
                    }
                    $updates{$aid} = \%single;
                }
            }
            if (%updates) {
                Dlog_debug { "Annotating with $_" } \%updates;
                my $res = $title->annotate(\%updates);
                if ($res->{success}) {
                    $c->flash(status_msg => $c->loc("Thanks!"));
                }
                else {
                    $c->flash(error_msg => $c->loc($res->{error} || 'Errors'));
                }
            }
            return $c->response->redirect($c->uri_for($title->full_uri));
        }
    }
    $c->detach('/bad_parameters');
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
