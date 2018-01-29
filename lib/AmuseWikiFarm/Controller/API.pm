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

sub api :Chained('/site') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub autocompletion :Chained('api') :Args(1) {
    my ($self, $c, $type) = @_;
    my $query = lc($type);
    if ($type =~ m/(topic|author)/) {
        my $type = $1;
        # include the deferred
        my @list = map { $_->{name} }
          @{$c->stash->{site}->categories->with_texts(deferred => 1)->by_type($type)->listing_tokens};
        $c->stash(json => \@list);
        $c->detach($c->view('JSON'));
    }
    else {
        $c->detach('/not_found');
    }
}

sub lexicon :Chained('api') :PathPart('lexicon.json') :Args(0) {
    my ($self, $c) = @_;
    my %out = (
               InvalidFileExtensionError => $c->loc("File format not allowed"),
               InvalidFileTypeError => $c->loc("File format not allowed"),
               MaxFileSizeError => $c->loc("File too big"),
               RequestError => $c->loc("Request failed! Please report the the problem"),
               'Unused attachment' => $c->loc("Unused attachment"),
               Remove => $c->loc("Remove"),
              );
    $c->stash(json => \%out);
    $c->detach($c->view('JSON'));
}

sub ckeditor :Chained('api') :Args(0) {
    my ($self, $c) = @_;
    my $lang = $c->stash->{current_locale_code} || 'en';
    my $config = {
                  language => $lang,
                  toolbar => 'AmuseWiki',
                  toolbar_AmuseWiki => [
                                        {
                                         name => 'document',
                                         items => [ 'Source'],
                                        },
                                        {
                                         name =>  'clipboard',
                                         items  =>  [
                                                     'Cut',
                                                     'Copy',
                                                     'Paste',
                                                     'PasteText',
                                                     'PasteFromWord',
                                                     '-',
                                                     'Undo',
                                                     'Redo'
                                                    ],
                                        },
                                        {
                                         name =>  'editing',
                                         items  =>  [
                                                      'Find',
                                                      'Replace',
                                                      '-',
                                                      'SelectAll',
                                                     ],
                                        },
                                        {
                                         name =>  'basicstyles',
                                         items  =>  [
                                                     'Bold',
                                                     'Italic',
                                                     '-',
                                                     'RemoveFormat'
                                                    ],
                                        },
                                        {
                                         name => 'paragraph',
                                         items  => [
                                                    'NumberedList',
                                                    'BulletedList',
                                                    '-',
                                                    'Blockquote',
                                                   ],
                                        },
                                        {
                                         name =>  'styles',
                                         items  => [ 'Format'],
                                        }
                                       ],
                 };
    $c->stash(json => $config);
    $c->detach($c->view('JSON'));
}

=head1 AUTHOR

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
