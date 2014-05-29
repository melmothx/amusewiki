package AmuseWikiFarm::Controller::Special;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Special - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller for the special pages. Special pages are stored in
the DB, and use the markup only for editing, storing a local copy of
the .muse file.

=head1 METHODS

=cut


=head2 root

=head2 entry

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my @texts = $c->stash->{site}->titles->published_specials;
    $c->stash(texts => \@texts,
              baseurl => $c->uri_for_action('/special/index'),
              template => 'library.tt');
}

sub display :Path :Args(1) {
    my ($self, $c, $page) = @_;
    my $site = $c->stash->{site};

    # has extension? serve it if found
    if ($page =~ m/\./) {
        if (my $attach = $site->attachments->by_uri($page)) {
            $c->serve_static_file($attach->f_full_path_name);
            return;
        }
    }
    else {
        if (my $page = $site->titles->published_specials->find({ uri => $page })) {
            $c->stash(
                      template => 'text.tt',
                      text => $page,
                      is_library_special => 1,
                     );
            return;
        }
    }
    $c->detach('/not_found');
}

sub special_edit :Path :Args(2) {
    my ($self, $c, $text, $action) = @_;
    if ($action eq 'edit') {
        $c->log->debug("$text => $action");
        $c->response->redirect($c->uri_for_action('/edit/revs', [special => $text]));
    }
    else {
        $c->detach('/not_found');
    }
}




=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
