package AmuseWikiFarm::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

use AmuseWikiFarm::Log::Contextual;
use Template::Filters;
use AmuseWikiFarm::Utils::Amuse qw/amw_meta_stripper/;

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
