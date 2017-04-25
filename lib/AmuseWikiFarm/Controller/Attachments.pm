package AmuseWikiFarm::Controller::Attachments;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

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
    $c->stash(full_page_no_side_columns => 1,
              attachments => $attachments,
             );
}

sub list :Chained('root') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    my @list;
    my $all = $c->stash->{attachments}->search(undef, { order_by => 'uri' });
    while (my $att = $all->next) {
        push @list, {
                     full_uri => $c->uri_for($att->full_uri),
                     name => $att->uri,
                     thumb => $c->uri_for($att->small_uri),
                    };
    }
    $c->stash(attachments_list => \@list);
}

sub attachment :Chained('root') :PathPart('') :CaptureArgs(1) {
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
