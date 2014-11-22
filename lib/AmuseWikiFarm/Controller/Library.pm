package AmuseWikiFarm::Controller::Library;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Utils::Amuse qw/muse_naming_algo/;
use HTML::Entities qw/decode_entities/;

=head1 NAME

AmuseWikiFarm::Controller::Library - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 root

Empty base method to start the chain

=cut

sub root :Chained('/') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash(please_index => 1);
}

=head2 Listing

=over 4

=item regular_list

Mapping to /library

=item regular_list_display

Forward to C<template_listing>

=item special_list

Mapping to /special

=item special_list_display

Forward to C<template_listing>

=item template_listing

Render the library.tt template using the texts in the C<texts_rs>
stash.

=back

=cut

sub regular_list :Chained('root') :PathPart('library') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->log->debug('stashing f_class');
    my $rs = $c->stash->{site}->titles->published_texts;
    $c->stash(
              f_class => 'text',
              texts_rs => $rs,
              page_title => $c->loc('Full list of texts'),
              nav => 'titles',
             );
}

sub archive_list :Chained('root') :PathPart('archive') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->forward('regular_list');
}

sub special_list :Chained('root') :PathPart('special') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->log->debug('stashing f_class');
    my $rs = $c->stash->{site}->titles->published_specials;
    $c->stash(
              f_class => 'special',
              texts_rs => $rs,
              page_title => $c->loc('Special pages'),
             );
}

sub archive :Chained('archive_list') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    $c->forward('template_listing');
}

sub regular_list_display :Chained('regular_list') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    $c->forward('template_listing');
}

sub special_list_display :Chained('special_list') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    $c->forward('template_listing');
}

sub template_listing :Private {
    my ($self, $c) = @_;
    my $rs = delete $c->stash->{texts_rs};
    # these should be cached
    my $cache = $c->model('Cache',
                          site_id => $c->stash->{site}->id,
                          type => 'library-' . $c->stash->{f_class},
                          resultset => $rs,
                         );
    $c->stash(texts => $cache->texts,
              pager => $cache->pager,
              template => 'library.tt');
}

sub archive_by_lang :Chained('archive_list') :PathPart('') :Args(1) {
    my ($self, $c, $lang) = @_;
    my $rs = delete $c->stash->{texts_rs};
    $c->log->debug("In $lang");
    if (my $label = $c->stash->{site}->known_langs->{$lang}) {
        my $resultset = $rs->search({ lang => $lang });
        my $cache = $c->model('Cache',
                              site_id => $c->stash->{site}->id,
                              type => 'library-' . $c->stash->{f_class},
                              subtype => $lang,
                              resultset => $resultset,
                             );
        $c->stash(texts => $cache->texts,
                  pager => $cache->pager,
                  multilang => {
                                filter_lang => $lang,
                                filter_label => $label,
                               },
                  template => 'library.tt');
        return;
    }
    $c->detach('/not_found');
}


=head2 text

Path: /library/*

Main method to serve the files, mapping them to the real location.

=cut

sub special_match :Chained('special_list') PathPart('') :CaptureArgs(1) {
    my ($self, $c, $uri) = @_;
    $c->forward('text_matching', [ $uri ]);
}

sub regular_match :Chained('regular_list') PathPart('') :CaptureArgs(1) {
    my ($self, $c, $uri) = @_;
    $c->forward('text_matching', [ $uri ]);
}


sub special :Chained('special_match') PathPart('') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(latest_entries => [ $c->stash->{site}->titles->latest ]);
    $c->forward('text_serving');
}

sub text    :Chained('regular_match') PathPart('') :Args(0) {
    my ($self, $c) = @_;
    $c->forward('text_serving');
}

sub special_edit :Chained('special_match') PathPart('edit') :Args(0) {
    my ($self, $c) = @_;
    $c->forward('redirect_to_edit');
}

sub regular_edit :Chained('regular_match') PathPart('edit') :Args(0) {
    my ($self, $c) = @_;
    $c->forward('redirect_to_edit');

}

sub redirect_to_edit :Private {
    my ($self, $c) = @_;
    my $text = $c->stash->{text};
    $c->response->redirect($c->uri_for_action('/edit/revs', [$text->f_class,
                                                             $text->uri]));
}


sub text_matching :Private {
    my ($self, $c, $arg) = @_;
    my $name = $arg;
    my $ext = '';
    my $append_ext = '';
    my $site = $c->stash->{site};

    # strip the extension
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

    $c->log->debug("Ext is $ext, name is $name");

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
    my $canonical = muse_naming_algo($name);
    $c->log->debug("canonical is $canonical");

    # find the title or the attachment
    if (my $text = $c->stash->{texts_rs}->find({ uri => $canonical})) {
        $c->stash(text => $text);
        if ($canonical ne $name) {
            my $location = $c->uri_for($text->full_uri);
            $c->response->redirect($location, 301);
            $c->detach();
            return;
        }
        # static files are served here
        if ($ext) {
            $c->log->debug("Got $canonical $ext => " . $text->title);
            my $served_file = $text->filepath_for_ext($ext);
            if (-f $served_file) {
                $c->stash(serve_static_file => $served_file);
                $c->detach($c->view('StaticFile'));
                return;
            }
            else {
                # this should not happen
                $c->log->warn("File $served_file expected but not found!");
                $c->detach('/not_found');
                return;
            }
        }
    }
    elsif (my $attach = $site->attachments->by_uri($canonical . $append_ext)) {
        $c->log->debug("Found attachment $canonical$append_ext");
        if ($name ne $canonical) {
            $c->log->warn("Using $canonical instead of $name, shouldn't happen");
        }
        $c->stash(serve_static_file => $attach->f_full_path_name);
        $c->detach($c->view('StaticFile'));
        return;
    }
    else {
        $c->stash(uri => $canonical);
        $c->detach('/not_found');
    }
}

sub text_serving :Private {
    my ($self, $c) = @_;
    # search the damned title.
    my $text = $c->stash->{text} or die "WTF?";
    $c->stash(
              template => 'text.tt',
              text => $text,
              page_title => decode_entities($text->title),
             );
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
