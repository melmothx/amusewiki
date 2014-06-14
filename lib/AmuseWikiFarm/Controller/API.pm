package AmuseWikiFarm::Controller::API;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::API - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut



=head2 index

=cut

use JSON qw/encode_json/;

sub autocompletion :Local :Args(1) {
    my ($self, $c, $type) = @_;
    my $query = lc($type);
    if ($type =~ m/(topic|author)/) {
        my $cats = $c->stash->{site}->categories;
        my @list;
        my $result = $cats->by_type($1)->search({}, { columns => qw/name/ });
        while (my $row = $result->next) {
            push @list, $row->name;
        }
        $c->response->content_type('application/json; charset=UTF-8');
        $c->response->body(encode_json(\@list));
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
