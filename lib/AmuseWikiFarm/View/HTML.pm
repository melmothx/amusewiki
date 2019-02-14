package AmuseWikiFarm::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

use AmuseWikiFarm::Log::Contextual;
use Template::Filters;
use AmuseWikiFarm::Utils::Amuse qw/amw_meta_stripper to_json/;
use URI;

$Template::Filters::FILTERS->{escape_invisible_chars} = \&escape_invisible_chars;
$Template::Filters::FILTERS->{escape_js} = \&escape_js_string;

sub escape_invisible_chars {
    my $s = shift;
    $s =~ s/([\x{ad}\x{a0}])/sprintf('<U+%04X>', ord($1))/ge;
    return $s;
}

sub escape_js_string {
    my $s = shift;
    $s =~ s/(\\|'|"|\/)/\\$1/g;
    return $s;
};

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    ENCODING => 'utf8',
    WRAPPER => 'wrapper.tt',
    PRE_PROCESS => 'macros.tt',
    render_die => 1,
);

before process => sub {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};
    return unless $site;
    if ($c->request->query_params->{bare}) {
        $c->stash(no_wrapper => 1);
    }
    unless ($c->stash->{no_wrapper}) {
        log_debug { "Doing the layout fixes" };

        $self->add_navigation_menus($c, $site);

        # display number of pending revisions in the user menu
        if ($c->user_exists) {
            $c->stash->{site_pending_revisions} = $site->revisions->pending->count;
        }

        # warn about failed jobs in the user menu
        if ($c->user_exists and $c->check_any_user_role(qw/admin root/)) {
            $c->stash->{site_failed_jobs} = $site->jobs->failed_jobs->count;
        }

        # layout adjustments
        my $theme = $site->bootstrap_theme;
        my $columns = 12;
        unless ($c->stash->{full_page_no_side_columns}) {
            my $left_column = $site->left_layout_html;
            my $right_column = $site->right_layout_html;
            if ($left_column || $right_column) {
                my $wide = 4;
                # enlarge the column if we have only one sidebar
                if ($left_column && $right_column) {
                    $wide = 2;
                }
                $c->stash(left_layout_html => $left_column,
                          right_layout_html => $right_column,
                          left_layout_cols => ($left_column ? $wide : 0),
                          right_layout_cols => ($right_column ? $wide : 0),
                         );
                $columns = 8;
            }
        }
        if (my $meta_desc = $c->stash->{meta_description}) {
            $c->stash(meta_description => amw_meta_stripper($meta_desc));
        }
        $self->add_open_graph($c);
        my $sitelink = {
                        '@context' => 'http://schema.org',
                        '@type' => "WebSite",
                        'url' => $c->uri_for('/')->as_string,
                        'potentialAction' => {
                                              '@type' => "SearchAction",
                                              'target' => $c->uri_for_action('/search/index') . '?query={search_term_string}',
                                              'query-input' => "required name=search_term_string"
                                             },
                       };
        $c->stash(
                  site_is_without_authors => $site->is_without_authors($c->user_exists),
                  site_is_without_topics => $site->is_without_topics($c->user_exists),
                  bootstrap_css => "/static/css/bootstrap.$theme.css",
                  main_body_cols => $columns,
                  top_layout_html => $site->top_layout_html,
                  bottom_layout_html => $site->bottom_layout_html,
                  sitelinks_searchbox => to_json($sitelink, pretty => 1, canonical => 1),
                 );
    }
};

=head2 add_open_graph

From the specs (L<http://ogp.me>)

=over 4

=item og:title

The title of your object as it should appear within the graph, e.g., "The Rock".

We look into page_title, which should already set. Otherwise we fall
back to the site description.

=item og:type

The type of your object, e.g., "video.movie". Depending on the type you specify, other properties may also be required.

If a text object is stashed, we can set it to C<book> or C<article> +
C<$type:author> + C<$type:tag> with topics, otherwise it's C<website>

=item og:image

An image URL which should represent your object within the graph. If
it's a text object, we could have a cover attached. Otherwise default
to the site logo. Skip the whole thing if we don't have that, as it's
mandatory.

=item og:url

The canonical URL of your object that will be used as its permanent ID
in the graph, e.g., "http://www.imdb.com/title/tt0117500/".

If C<page_title> is not set, default to the root. Otherwise parse
$c->request->uri, stripping reserved params (prefixed by C<__>). If
I'm not mistaken, we don't have different access urls for the same
resources, so it's always the canonical.

=item og:description

This is optional, use the meta_description if set.

=item og:site_name

This is optional, but we should have it.

=item og:locale and og:locale:alternate (string).

Optional, but we should have it. We need the language_TERRITORY, though.

=back

=cut

sub add_open_graph {
    my ($self, $c) = @_;
    if (my $site = $c->stash->{site}) {
        my $image;
      SEARCHIMAGE:
        foreach my $i (qw/opengraph.png pagelogo.png navlogo.png/) {
            if (my $found = $site->site_files->min_dimensions(200, 200)->single({ file_name => $i })) {
                $image = $found;
                log_debug { "Found $i, stashing apple_touch_icon " . $image->file_name . ' ' . $image->mime_type };
                $c->stash(apple_touch_icon => $c->uri_for_action('/sitefiles/local_files',
                                                                 [ $site->id, $image->file_name ]));
                $c->stash(apple_touch_icon_mime_type => $image->mime_type);
                last SEARCHIMAGE;
            }
        }
        if ($image) {
            # ok, we have an image, we can proceed
            my @opengraph;
            my $title = $c->stash->{page_title} || $site->sitename;
            if ($title) {
                push @opengraph, { p => 'og:title', c => $title  };
            }
            else {
                # cannot proceed, this is a broken setup and shouldn't happen
                return;
            }
            my $text = $c->stash->{text};
            if ($text and ref($text) and $text->can('text_qualification')) {
                my $type = $text->text_qualification || 'article';
                push @opengraph, { p => 'og:type', c => $type };
                if (my $author = $text->author) {
                    push @opengraph, { p => "og:$type:author", c => $author };
                }
                if (my $topics = $c->stash->{text_topics}) {
                    if (ref($topics) and ref($topics) eq 'ARRAY') {
                        foreach my $topic (@$topics) {
                            push @opengraph, { p => "og:$type:tag", c => $c->loc($topic->{name}) }
                              if $topic->{name};
                        }
                    }
                }
                if (my $cover = $text->cover_file) {
                    # this return an attachment object
                    if (my $thumb = $cover->thumbnails->min_dimensions(200, 200)->first) {
                        $image = $thumb;
                    }
                }
            }
            else {
                push @opengraph, { p => 'og:type', c => 'website' };
            }
            my $image_url = $image->is_site_file ?
              $c->uri_for_action('/sitefiles/local_files',
                                 [ $site->id, $image->file_name ])
              :
              $c->uri_for_action('/uploads/thumbnail',
                                 [ $site->id, $image->file_name ]);

            push @opengraph, ({
                               p => 'og:image',
                               c => $image_url,
                              },
                              {
                               p => 'og:image:width',
                               c => $image->image_width,
                              },
                              {
                               p => 'og:image:height',
                               c => $image->image_height,
                              });
            my $uri = $c->request->uri->clone;
            my %query = $uri->query_form; # don't mind if the param is repeated twice.
            foreach my $k (keys %query) {
                delete $query{$k} if $k =~ m/^__/;
            }
            $uri->query_form(%query);
            my $base = $site->canonical_url_secure;
            # unclear what happens if the app is mounted, but in this
            # case I think that's the last of our problems.
            push @opengraph, { p => 'og:url', c => $base . $uri->path_query };

            if (my $site_name = $site->sitename) {
                push @opengraph, { p => 'og:site_name', c => $site_name  };
            }
            if (my $desc = $c->stash->{meta_description} || $title) {
                push @opengraph, { p => 'og:description', c => $desc };
            }
            $c->stash(open_graph => \@opengraph) if @opengraph;
        }
    }
}

sub add_navigation_menus {
    my ($self, $c, $site) = @_;

    my @related = map {
        +{ uri =>  $_->canonical_url, name => $_->sitename || $_->canonical }
    } $site->other_sites;

    my @specials = map {
        +{ uri => $_->full_uri, name => $_->title || $_->rui }
    } $site->titles->published_specials->search({ uri => { -not_like => 'index%' } },
                                                { columns => [qw/title uri f_class/] });

    my %out = (
               projects => \@related,
               specials => \@specials,
               archive  => [],
              );

    foreach my $link ($site->site_links->search(undef, { order_by => [qw/sorting_pos url/] })) {
        if ($out{$link->menu}) {
            push @{$out{$link->menu}}, {
                                        uri => $link->url,
                                        name => $link->label || $link->url
                                       };
        }
    }
    foreach my $menu (keys %out) {
        if (@{$out{$menu}}) {
            foreach my $link (@{$out{$menu}}) {
                unless ($link->{uri} =~ m{https?://}) {
                    $link->{uri} = $c->uri_for($link->{uri});
                }
                $link->{active} = $link->{uri} eq $c->request->uri;
            }
        }
        else {
            delete $out{$menu}; # nothing to show
        }
    }
    $c->stash(navigation => \%out);
}


=head1 NAME

AmuseWikiFarm::View::HTML - TT View for AmuseWikiFarm

=head1 DESCRIPTION

TT View for AmuseWikiFarm.

=head1 SEE ALSO

L<AmuseWikiFarm>

=head1 AUTHOR

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
