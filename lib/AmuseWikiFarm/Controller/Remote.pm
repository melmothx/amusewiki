package AmuseWikiFarm::Controller::Remote;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Utils::Amuse qw/clean_username/;

=head1 NAME

AmuseWikiFarm::Controller::Remote - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub root :Chained('/site_user_required') :PathPart('remote') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub create :Chained('root') :PathPart('create') :Args(0) {
    my ($self, $c) = @_;
    die "Shouldn't happen" unless $c->user_exists;
    my %params = %{$c->request->body_params};
    foreach my $k (keys %params) {
        delete $params{$k} if $k =~ m/^__/;
    }
    my $response = {};
    if ($params{title} && $params{textbody}) {
        my $site = $c->stash->{site};
        my ($revision, $error) = $site->create_new_text(\%params, 'text');
        my $user = $c->user->get("username");
        if ($revision) {
            $revision->commit_version("Upload from /remote/create",
                                      clean_username($user));
            $revision->discard_changes;
            my $job = $site->jobs->publish_add($revision);
            $response->{url} = $c->uri_for($revision->title->full_uri)->as_string;
            $response->{job} = $c->uri_for_action('/tasks/display',  [$job->id])->as_string;
        }
        else {
            $response->{error} = $error;
        }
    }
    else {
        $response->{error} = "Missing mandatory title and textbody parameters";
    }
    $c->stash(json => $response);
    $c->logout;
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
