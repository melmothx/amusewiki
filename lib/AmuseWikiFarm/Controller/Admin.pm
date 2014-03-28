package AmuseWikiFarm::Controller::Admin;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Admin - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched AmuseWikiFarm::Controller::Admin in Admin.');
}

=head2 debug_site_id

Show the site id.

=cut

sub debug_site_id :Local :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body(join(" ",
                            $c->stash->{site}->id,
                            $c->stash->{site}->locale,
                           ));
}

=head2 pending

List and act on the existing revisions

=cut

sub pending :Local :Args(0) {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};
    if (my $revid = $c->request->params->{publish}) {
        # TODO validate the params
        my $rev = $site->revisions->find($revid);
        if ($rev and $rev->status eq 'ready') {
            my $data = { id => $rev->id };
            my $job_id = $c->model('Queue')->publish_add($rev->site_id, $data);
            $rev->status('processing');
            $rev->update;
            $c->res->redirect($c->uri_for_action('/tasks/display', [$job_id]));
            return;
        }
        else {
            $c->flash(error_msg => "Bad revision!");
        }
    }

    my @search = ({},
                  { order_by => { -desc => 'updated' } });

    my @revisions = $site->revisions->search(@search);
    $c->stash(revisions => \@revisions);


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
