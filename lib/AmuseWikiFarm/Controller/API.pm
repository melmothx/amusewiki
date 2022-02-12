package AmuseWikiFarm::Controller::API;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Utils::Paths;
use AmuseWikiFarm::Utils::Amuse;
use IO::File;

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
    my @list;
    if ($type =~ m/(topic|author)/) {
        my $type = $1;
        # include the deferred
        @list = map { $_->{name} }
          @{$c->stash->{site}->categories->with_texts(deferred => 1)->by_type($type)->listing_tokens};
    }
    elsif ($type eq 'adisplay') {
        @list = @{$c->stash->{site}->titles->list_display_authors};
    }
    Dlog_debug { "Found list for $type:  $_" } \@list;
    $c->stash(json => \@list);
    $c->detach($c->view('JSON'));
}

sub check_existing_uri :Chained('api') :PathPart('check-existing-uri') :Args(0) {
    my ($self, $c) = @_;
    my %out;
    if (my $uri = $c->request->params->{uri}) {
        # check if valid
        my $cleaned = AmuseWikiFarm::Utils::Amuse::muse_naming_algo($uri);
        if ($uri eq $cleaned) {
            if ($c->stash->{site}->titles->search({ uri => "$uri" })->count) {
                $out{error} = $c->loc("Such URI already exists");
            }
            else {
                $out{success} = $uri;
            }
        }
        else {
            $out{error} = $c->loc("Invalid URI");
        }
    }
    $c->stash(json => \%out);
    $c->detach($c->view('JSON'));
}

sub lexicon :Chained('api') :PathPart('lexicon.json') :Args(0) {
    my ($self, $c) = @_;
    my %out = (
               InvalidFileExtensionError => $c->loc("File format not allowed"),
               InvalidFileTypeError => $c->loc("File format not allowed"),
               MaxFileSizeError => $c->loc("File too big"),
               RequestError => $c->loc("Request failed! Please report the the problem"),
              );
    foreach my $js_string (
                           'Unused attachment',
                           'Remove',
                           'Insert the file into the body',
                           'Use the image as cover',
                           'File already in the body',
                           'Image already set as cover',
                           'Insert the file into the body at the cursor position',
                           'Please remove this file from the body first',
                           'Use the image as cover',
                          ) {
        $out{$js_string} = $c->loc($js_string);
    }
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

sub legacy_links :Chained('api') :PathPart('legacy-links') :Args(0) {
    my ($self, $c)  = @_;
    my @redirections = $c->stash->{site}->legacy_links
      ->search(undef,
               {
                columns => [qw/legacy_path new_path/],
                result_class => 'DBIx::Class::ResultClass::HashRefInflator',
               })->all;
    my %out;
    foreach my $r (@redirections) {
        $out{$r->{legacy_path}} = $r->{new_path};
    }
    $c->stash(json => \%out);
    $c->detach($c->view('JSON'));
}


sub datatables_lang :Chained('api') :PathPart('datatables-lang') :Args(0) {
    my ($self, $c) = @_;
    my %langs = (
                 tr => 'Turkish',
                 ru => 'Russian',
                 hr => 'Croatian',
                 it => 'Italian',
                 he => 'Hebrew',
                 fa => 'Persian',
                 ar => 'Arabic',
                 cs => 'Czech',
                 da => 'Danish',
                 pt => 'Portuguese',
                 pl => 'Polish',
                 sv => 'Swedish',
                 sr => 'Serbian_latin',
                 sq => 'Albanian',
                 en => 'English',
                 nl => 'Dutch',
                 fr => 'French',
                 de => 'German',
                 id => 'Indonesian',
                 mk => 'Macedonian',
                 es => 'Spanish',
                 fi => 'Finnish',
                 bg => 'Bulgarian',
                 el => 'Greek',
                 eo => 'Esperanto',
                 zh => 'Chinese',
                 ja => 'Japanese',
                 tl => 'English',
                 ceb => 'English',
                );
    my $lang = $c->stash->{current_locale_code} || 'en';
    if (my $data_file = $langs{$lang}) {
        my $base = AmuseWikiFarm::Utils::Paths::static_file_location();
        my $file = $base->child(qw/js datatables i18n/, $data_file . '.json');
        if ($file->exists) {
            $c->response->content_type('application/json');
            $c->response->body(IO::File->new("$file", 'r'));
            return;
        }
    }
    $c->response->body("Not found");
    $c->response->status(404);
}

sub latest :Chained('api') :PathPart('latest') :Args {
    my ($self, $c, $page) = @_;
    my $site = $c->stash->{site};
    my @out = $site->titles->status_is_published
      ->texts_only
      ->order_by('pubdate_desc')
      ->page_number($page)
      ->rows_number($site->pagination_size_latest)
      ->search(undef, {
                       columns => [qw/id
                                      title
                                      subtitle
                                      lang
                                      date
                                      notes
                                      source
                                      list_title
                                      author
                                      uid
                                      attach
                                      pubdate
                                      status
                                      parent
                                      publisher
                                      isbn
                                      rights
                                      seriesname
                                      seriesnumber
                                      cover
                                      teaser
                                      sku
                                      uri
                                     /],
                       prefetch => [
                                    'muse_headers',
                                    { title_categories => 'category'},
                                   ],
                       result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                      })->all;
    $c->stash(json => \@out);
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
