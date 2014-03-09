package AmuseWikiFarm::Controller::Search;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Search - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my $site = $c->stash->{site};
    my $xapian = $c->model('Xapian');
    my ($matches, @results) = $xapian->search($c->req->params->{query},
                                              $c->req->params->{page});

    foreach my $res (@results) {
        $res->{text} = $site->titles->by_uri($res->{pagename});
    }

    $c->stash( matches => $matches,
               text_uri_base => $c->uri_for_action('/library/index'),
               results => \@results );
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
