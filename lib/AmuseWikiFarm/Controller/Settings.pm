package AmuseWikiFarm::Controller::Settings;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Settings - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub settings :Chained('/site_user_required') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub list_custom_formats :Chained('settings') :PathPart('formats') :CaptureArgs(0) {
    my ($self, $c) = @_;
    unless ($c->check_any_user_role(qw/admin root/)) {
        $c->detach('/not_permitted');
        return;
    }
}

sub formats :Chained('list_custom_formats') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    my @list;
    my $formats = $c->stash->{site}->custom_formats;
    while (my $format = $formats->next) {
        push @list, {
                     edit_url => $c->uri_for_action('/settings/edit_format',
                                                    $format->custom_formats_id),
                     delete_url => $c->uri_for_action('/settings/delete_format',
                                                      $format->custom_formats_id),
                     name => $format->format_name,
                     description => $format->format_description,
                     active => $format->active,
                    };
    }
    $c->stash(
              format_list => \@list,
              create_url => $c->uri_for_action('/settings/create_format'),
             );
}

sub edit_format :Chained('list_custom_formats') :PathPart('edit') :Args(1) {
    my ($self, $c, $id) = @_;
}

sub create_format :Chained('list_custom_formats') :PathPart('create') :Args(0) {
    my ($self, $c) = @_;
}

sub delete_format :Chained('list_custom_formats') :PathPart('delete') :Args(1) {
    my ($self, $c, $id) = @_;
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
