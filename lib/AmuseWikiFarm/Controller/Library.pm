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
    $c->stash(baseurl => $c->uri_for_action('/library/index'));
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
                      zip     |

                      # these two need special treatment
                      jpe?g   |
                      png
                  )$
                 /x) {
        $name = $1;
        $ext  = $2;
    }

    $c->log->debug("Ext is $ext");

    if ($ext) {
        $append_ext = '.' . $ext;

        my %managed = $site->available_text_exts;
        if (exists $managed{$append_ext}) {
            unless ($managed{$append_ext}) {
                $c->log->debug("$ext is not provided");
                $c->detach('/not_found');
            }
        }
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
            my $served_file = $text->filepath_for_ext($ext);
            if (-f $served_file) {
                $c->serve_static_file($served_file);
            }
            else {
                # this should not happen
                $c->log->warn("File $served_file expected but not found!");
                $c->detach('/not_found');
            }
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

=head2 text_edit

Path: /library/<text>/edit

Redirects to /edit/<text>

=cut

sub text_edit :Path :Args(2) {
    my ($self, $c, $text, $action) = @_;
    if ($action eq 'edit') {
        $c->log->debug("$text => $action");
        $c->response->redirect($c->uri_for_action('/edit/revs', [$text]));
    }
    else {
        $c->detach('/not_found');
    }
}

=head2 random

Path: /random

Get the a random text

=cut

sub random :Global :Args(0) {
    my ($self, $c) = @_;
    my $text = $c->stash->{site}->titles->random_text;
    $c->response->redirect($c->uri_for_action('/library/text' => $text->uri));
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
