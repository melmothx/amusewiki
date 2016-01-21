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

sub api :Chained('/site') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub autocompletion :Chained('api') :Args(1) {
    my ($self, $c, $type) = @_;
    my $query = lc($type);
    if ($type =~ m/(topic|author)/) {
        my $cats = $c->stash->{site}->categories;
        my @list;
        my $result = $cats->by_type($1)->active_only
          ->search(undef, { columns => qw/name/ });
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
    $c->response->content_type('application/json; charset=UTF-8');
    $c->response->body(encode_json($config));
}

=head1 AUTHOR

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
