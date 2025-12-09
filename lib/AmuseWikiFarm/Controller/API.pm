package AmuseWikiFarm::Controller::API;
use utf8;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Utils::Paths;
use AmuseWikiFarm::Utils::Amuse;
use IO::File;
use HTML::Entities;

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

    # legacy
    if ($type =~ m/^(sort|list)?(topic|author)s$/) {
        $type = $2;
    }
    my @list;
    if ($type eq 'displayed_author') {
        @list = @{$c->stash->{site}->titles->list_display_authors};
    }
    else {
        # include the deferred
        @list = map { decode_entities($_->{name}) }
          @{$c->stash->{site}->categories->with_texts(deferred => 1)->by_type($type)->listing_tokens};
    }
    Dlog_debug { "Found list for $type:  $_" } \@list;
    $c->stash(json => \@list);
    $c->detach($c->view('JSON'));
}

sub check_existing_uri :Chained('api') :PathPart('check-existing-uri') :Args(0) {
    my ($self, $c) = @_;
    my %out;
    if (my $uri = $c->request->params->{uri}) {
        my $type = $c->request->params->{type} || 'title';
        my $site = $c->stash->{site};
        # check if valid
        my $cleaned = AmuseWikiFarm::Utils::Amuse::muse_naming_algo($uri);
        if ($uri eq $cleaned) {
            my $exists;
            if ($type eq 'title') {
                $exists = $site->titles->by_uri($uri)->count;
            }
            elsif ($type eq 'aggregation_series') {
                $exists = $site->aggregation_series->by_uri($uri)->count;
            }
            elsif ($type eq 'aggregation') {
                $exists = $site->aggregations->by_uri($uri)->count;
            }
            elsif ($type eq 'nodes') {
                $exists = $site->nodes->by_uri($uri)->count;
            }

            if ($exists) {
                $out{error} = $c->loc("Such URI already exists");
            }
            elsif (defined $exists) {
                $out{success} = $uri;
            }
            else {
                $out{error} = $c->loc("Bad type. This is a bug");
            }
        }
        else {
            $out{error} = $c->loc("Invalid URI");
        }
    }
    $c->stash(json => \%out);
    $c->detach($c->view('JSON'));
}

sub get_generated_uri :Chained('api') :PathPart('get-generated-uri') :Args(0) {
    my ($self, $c) = @_;
    my $params = {
                  %{$c->request->query_params},
                  %{$c->request->body_params}
                 };
    Dlog_debug { "Params are $_" } $params;

    my $uri;
    my $site = $c->stash->{site};
    my $author = $params->{author} // "";
    my $title  = $params->{title}  // "";
    my $lang = $params->{lang} || $site->locale;
    if ($title =~ m/\w/) {
        my $string = "$author $title";
        if ($site->multilanguage or $lang ne $site->locale) {
            $string = substr($string, 0, 90) . ' ' . $lang;
        }
        my $base = AmuseWikiFarm::Utils::Amuse::muse_naming_algo($string);
        $uri = $base;
        my $count = 0;
        while ($count < 100 and $site->titles->search({ uri => "$uri" })->count) {
            log_info { "$uri already exists" };
            $count++;
            $uri = $base . '-' . $count;
        }
    }
    $c->stash(json => { uri => $uri });
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
                 ca => 'Catalan',
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
                 kmr => 'English',
                 ro => 'Romanian',
                 fa => 'Persian',
                 uk => 'Ukrainian',
                 eu => 'Basque',
                 hu => 'Hungarian',
                 bn => 'Bangla',
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

sub attachments :Chained('api') :PathPart('attachment') :Args(1) {
    my ($self, $c, $uri) = @_;
    my $site = $c->stash->{site};
    my %out;
    if (my $att = $site->attachments->by_uri($uri)) {
        my %all = $att->get_columns;
        my @cols = (qw/uri id comment_muse comment_html title_muse title_html alt_text mime_type/);
        @out{@cols} = @all{@cols};
    }
    else {
        $out{error} = "not found";
    }
    $c->stash(json => \%out);
    $c->detach($c->view('JSON'));
}

sub format_definitions :Chained('api') :PathPart('format-definitions') :Args(0) {
    my ($self, $c) = @_;
    my $out = $c->stash->{site}->formats_definitions;
    $c->stash(json => $out);
    $c->detach($c->view('JSON'));
}

sub aggregations :Chained('api') :PathPart('aggregations') :Args(0) {
    my ($self, $c) = @_;
    my $out = [ map { $_->final_data } $c->stash->{site}->aggregations->sorted ];
    $c->stash(json => $out);
    $c->detach($c->view('JSON'));
}

sub series :Chained('api') :PathPart('series') :Args(0) {
    my ($self, $c) = @_;
    my $out = [ $c->stash->{site}->aggregation_series->sorted->hri ];
    $c->stash(json => $out);
    $c->detach($c->view('JSON'));
}


sub collections :Chained('api') :PathPart('collections') :Args(0) {
    my ($self, $c) = @_;
    my $out = [ $c->stash->{site}->nodes->sorted
                ->search(undef, { columns => [qw/node_id full_path uri canonical_title/] })->hri ];
    $c->stash(json => $out);
    $c->detach($c->view('JSON'));
}

sub titles :Chained('api') :PathPart('titles') :Args(0) {
    my ($self, $c) = @_;
    my @all = $c->stash->{site}->titles->texts_only->status_is_published
      ->search(undef, {
                       columns => [qw/uri title author/],
                       order_by => [qw/sorting_pos/],
                       result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                      })->all;
    foreach my $i (@all) {
        if ($i->{author}) {
            $i->{label} = "$i->{author} — $i->{title} ($i->{uri})";
        }
        else {
            $i->{label} = "$i->{title} ($i->{uri})";
        }
    }
    $c->stash(json => \@all);
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
