package AmuseWikiFarm::Controller::Utils;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use Text::Amuse::Preprocessor::HTML qw//;

=head1 NAME

AmuseWikiFarm::Controller::Utils - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub root :Chained('/site') :PathPart('utils') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub import :Chained('root') :PathPart('import') :Args(0) {
    my ($self, $c) = @_;
    if (my $html = $c->request->body_params->{html_body}) {
        my $muse = Text::Amuse::Preprocessor::HTML::html_to_muse($html);
        $c->stash(muse_body => $muse,
                  html_body => $html);
    }
}


=encoding utf8

=head1 AUTHOR

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
