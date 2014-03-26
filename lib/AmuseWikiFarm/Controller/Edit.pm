package AmuseWikiFarm::Controller::Edit;
use strict;
use warnings;
use utf8;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Edit - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 /new

Theis 

=cut

sub index :Path('/new') :Args(0) {
    my ($self, $c) = @_;

    # if there was a posting, process it
    if ($c->request->params->{go}) {
        my $model = $c->model('Edit');
        my $revision = $model->create_new($c->request->params);
        if ($revision) {
            $c->log->debug("All ok, found " . $revision->id);
            $c->flash->{status_msg} = $c->loc("Created new text");
        }
        else {
            $c->flash->{error_msg} = $c->loc($model->error);
            if (my $existing = $model->redirect) {
                $c->flash->{status_msg} = $existing;
            }
        }
    }

    # otherwise populate the stash and render the template
    my %available_languages = (
                               ru => 'Русский',
                               sr => 'Srpski',
                               hr => 'Hrvatski',
                               mk => 'Македонски',
                               fi => 'Suomi',
                               es => 'Español',
                               en => 'English',
                              );
    $c->stash(known_langs => \%available_languages);
}

=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
