package AmuseWikiFarm::Controller::BookBuilder::Ajax;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::BookBuilder::Ajax - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub root :Chained('/') :PathPart('bookbuilder/ajax') :CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->log->debug("In the ajax page");
}

sub status :Chained('root') :PathPart('status') :Args(1) {
    my ($self, $c, $job) = @_;
    my $json =  $c->model('Queue')->fetch_job_by_id_json($job);
    $c->res->content_type('application/json');
    $c->response->body($json);
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
