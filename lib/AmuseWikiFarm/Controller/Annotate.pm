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
          ANNOTATION:
            foreach my $ann ($site->annotations) {
                my $aid = $ann->annotation_id;
                if ($params->{"passed-$aid"}) {
                    my %single = (value => $params->{"value-$aid"});
                    if ($params->{"wipe-$aid"}) {
                        $single{remove} = 1;
                    }
                    elsif ($ann->annotation_type eq 'file') {
                        my ($upload) = $c->request->upload("file-$aid");
                        if ($upload) {
                            $single{file} = $upload->tempname;
                            $single{value} = $upload->basename;
                        }
                        else {
                            # skip if there's nothing to do do.
                            next ANNOTATION;
                        }
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
                    $c->flash(error_msg => $c->loc($res->{errors} || 'Errors'));
                }
            }
            return $c->response->redirect($c->uri_for($title->full_uri));
        }
    }
    $c->detach('/bad_parameters');
}

# this is open to anybody, so we chain from /site
sub annotation :Chained('/site') :PathPart('annotation') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub download :Chained('annotation') :Args(4) {
    my ($self, $c, $annotation_id, $type, $uri, $filename) = @_;
    my $site = $c->stash->{site};
    if ($annotation_id =~ m/\A\d+\z/a) {
        if (my $annotation = $site->annotations->find($annotation_id)) {
            my $object;
            if ($type eq 'aggregation') {
                $object = $site->aggregations->by_uri($uri)->single;
            }
            else {
                $object = $site->titles->by_type($type)->by_uri($uri)->single;
            }
            my $validate = $annotation->values_for_object($object);
            if ($validate and $validate->{file_path}) {
                $c->stash(serve_static_file => $validate->{file_path});
                return $c->detach($c->view('StaticFile'));
            }
        }
    }
    $c->detach('/not_found');
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
