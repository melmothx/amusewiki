package AmuseWikiFarm::Controller::Library;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Utils::Amuse qw/muse_naming_algo/;


=head1 NAME

AmuseWikiFarm::Controller::Library - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

List the titles.

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my @texts = $c->stash->{site}->titles->published_texts;
    $c->stash(texts => \@texts);
    $c->stash(baseurl => $c->uri_for($c->action));
    $c->stash(template => 'library.tt');
}

=head2 text

Path: /library/*

Main method to serve the files, mapping them to the real location.

TODO: if behind proxy, try to use an acceleration method.

=cut

sub text :Path :Args(1) {
    my ($self, $c, $arg) = @_;
    # strip the extension
    my $name = $arg;
    my $ext = '';
    my $append_ext = '';
    my $site = $c->stash->{site};
    if ($arg =~ m/(.+?) # name
                  \.   # dot
                  # and extensions we provide
                  (
                      a4\.pdf |
                      lt\.pdf |
                      pdf     |
                      html    |
                      tex     |
                      epub    |
                      muse    |

                      # these two need special treatment
                      jpe?g   |
                      png
                  )$
                 /x) {
        $name = $1;
        $ext  = $2;
    }

    $c->log->debug("Ext is $ext");

    # TODO
    # here we have to manage images too.

    # clean up, eventually redirect if doesn't match
    if ($ext) {
        $append_ext = '.' . $ext;
    }

    # assert we are using canonical names.
    # TODO make it permanent
    my $canonical = muse_naming_algo($name);
    if ($canonical ne $name) {
        $c->response->redirect($c->uri_for($c->action, $canonical . $append_ext));
        $c->detach();
    }

    # search the damned title.
    my $text = $site->titles->by_uri($canonical);

    if ($text) {
        if ($ext) {
            $c->log->debug("Got $canonical $ext => " . $text->title);
            $c->serve_static_file($text->filepath_for_ext($ext));
        }
        else {
            $c->stash(
                      template => 'text.tt',
                      text => $text,
                     );
        }
    }
    elsif (my $attach = $site->attachments->by_uri($canonical . $append_ext)) {
        $c->log->debug("Found attachment $canonical$append_ext");
        $c->serve_static_file($attach->f_full_path_name);
    }
    else {
        $c->detach('/not_found');
    }
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
