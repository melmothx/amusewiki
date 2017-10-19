package AmuseWikiFarm::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

use AmuseWikiFarm::Log::Contextual;
use Template::Filters;
use AmuseWikiFarm::Utils::Amuse qw/amw_meta_stripper/;
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

        my @related = $site->other_sites;
        my @specials = $site->special_list;
        for my $sp (@specials) {
            my $uri = $sp->{uri};
            $sp->{special_uri} = $uri;
            $sp->{uri} = $sp->{full_url} || $c->uri_for_action('/special/text', [ $uri ]);
            $sp->{active} = ($c->request->uri eq $sp->{uri});
        }

        # let's assume related will return self, and special index
        if (@related || @specials) {
            my $nav_hash = {};
            if (@related) {
                $nav_hash->{projects} = \@related;
            }
            if (@specials) {
                $nav_hash->{specials} = \@specials;
            }
            $c->stash(navigation => $nav_hash);
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
        $c->stash(
                  site_is_without_authors => $site->is_without_authors($c->user_exists),
                  site_is_without_topics => $site->is_without_topics($c->user_exists),
                  bootstrap_css => "/static/css/bootstrap.$theme.css",
                  main_body_cols => $columns,
                  top_layout_html => $site->top_layout_html,
                  bottom_layout_html => $site->bottom_layout_html,
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
        if ($site->has_site_file('navlogo.png')) {
            # ok, we have an image, we can proceed
            my @opengraph;
            my $default_image =  $c->uri_for_action('/sitefiles/local_files',
                                                    [ $site->id, 'navlogo.png' ]);
            # title
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
                if (my $cover_uri = $text->cover_uri) {
                    push @opengraph, { p => 'og:image', c => $c->uri_for($cover_uri) };
                }
                else {
                    push @opengraph, { p => 'og:image', c => $default_image };
                }
            }
            else {
                push @opengraph, { p => 'og:type', c => 'website' };
                push @opengraph, { p => 'og:image', c => $default_image };
            }
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
