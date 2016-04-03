package AmuseWikiFarm::Controller::Root;
use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller' }

use AmuseWikiFarm::Utils::Amuse qw//;
use AmuseWikiFarm::Log::Contextual;

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=encoding utf-8

=head1 NAME

AmuseWikiFarm::Controller::Root - Root Controller for AmuseWikiFarm

=head1 DESCRIPTION

This class provides the site selection and the theme management.

=head1 METHODS

Values always stashed for every action:

=over 4

=item site

The master L<AmuseWikiFarm::Schema::Result::Site> object. If the site
is not looked up correctly, a 404 is issued. At some point a special
page must be provided.

=item user_login_uri

The URI for the user login

=item current_locale_code

Locale code

=item current_locale_name

Locale name

=item navigation

(Present only if there are related sites or special pages).

=back

=cut

sub site_no_auth :Chained('/') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
    log_debug { $c->request->uri->as_string };

    # catch the host. ->uri is an URI object, as per doc.
    my $host = $c->request->uri->host;

    # lookup in the db: first the canonical, then the vhosts
    my $site = $c->model('DB::Site')->find({ canonical => $host });
    unless ($site) {
        if (my $vhost = $c->model('DB::Vhost')->find($host)) {
            $site = $vhost->site;
            # permit the access to the site only if it's the canonical
            # one this is kind of questionable, but it's a common SEO
            # strategy to avoid splitting the results.
            my $uri = $c->request->uri->clone;
            $uri->host($site->canonical);
            # log_debug { "Redirecting to " . $uri->as_string };
            # place a permanent redirect
            $c->response->redirect($uri->as_string, 301);
            $c->detach();
            return;
        }
        else {
            log_warn { "$host not found in vhosts" };
        }
    }
    unless ($site) {
        $c->detach('/not_permitted');
        return;
    }
    my $site_id = $site->id;
    log_debug { "Site ID for $host is $site_id, with locale " . $site->locale };
    log_debug { "session id is " . ($c->sessionid || '<none>') };


    # this means some fucker reused a cookie from another site to gain
    # access to this. A bit unlikely, but better now than later. So,
    # assert that the session belongs to the same site This is very
    # common with some vintage browser (IE, anyone) and some crappy
    # robots.
    if ($c->sessionid) {
        my $session_site_id = $c->session->{site_id} || '';
        if ($session_site_id ne $site_id) {
            Dlog_info {
                "Session mismatch, <$session_site_id> ne <$site_id>".
                  " deleting session, requesting " . $c->request->uri . " " . $_
              } ($c->session);
            $c->delete_session;
            die "This shouldn't happen" if $c->user_exists;
            # a this point, this is a bug
        }
    }

    log_debug { "User exists? " .  $c->user_exists };
    # stash the site object
    $c->stash(site => $site);

    # always stash the login uri, at some point it could be needed by
    # the layout
    my $login_uri = $c->uri_for_action('/user/login');
    if ($site->secure_site || $site->secure_site_only) {
        $login_uri->scheme('https');
    }
    $c->stash(user_login_uri => $login_uri);

    # force ssl for authenticated users
    if ($c->user_exists) {
        unless ($c->request->secure) {
            $c->forward('/redirect_to_secure');
        }
    }

    my $locale = $site->locale || 'en';
    # in case something weird happened
    unless ($site->known_langs->{$locale}) {
        log_error { "$locale is not recognized on $site_id " . $c->request->path };
        $locale = 'en';
    }

    if ($site->multilanguage) {
        if ($c->sessionid) {
            if (my $user_locale = $c->session->{user_locale}) {
                if (my $language = $site->known_langs->{$user_locale}) {
                    log_debug { "Language is $language" };
                    # validated by now
                    $locale = $user_locale;
                }
            }
        }
    }
    $c->stash(current_locale_code => $locale,
              current_locale_name => $site->known_langs->{$locale},
             );
    # set the localization
    $c->set_language($locale, $site_id);

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
    return 1;
}

sub site :Chained('site_no_auth') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
    if ($c->stash->{site}->is_private and !$c->user_exists) {
        $c->response->redirect($c->uri_for('/login',
                                           { goto => $c->req->path }));
        $c->detach();
    }
}

sub site_robot_index :Chained('site') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash(please_index => 1);
}


sub not_found :Private {
    my ($self, $c) = @_;
    $c->stash(please_index => 0);
    log_debug { "In the not_found!" };
    # last chance: look into the redirections if we have a type and an uri,
    # set in C::Library or C::Category
    if (my $site = $c->stash->{site}) {
        if (my $f_class = $c->stash->{f_class}) {
            if (my $uri = $c->stash->{uri}) {
                if (my $red = $site->redirections->find({
                                                         type => $f_class,
                                                         uri => $uri
                                                        })) {
                    $c->response->redirect($c->uri_for($red->full_dest_uri));
                    $c->detach();
                    return;
                }
            }
        }
    }
    $c->response->status(404);
    log_info {
        $c->request->uri
          . " not found by " . ($c->request->user_agent || '')
          . " referred by " . ($c->request->referer || '')
      };
    $c->stash(error_msg => $c->loc("Page not found!"));
    $c->stash(template => "error.tt");
}

sub not_permitted :Private {
    my ($self, $c) = @_;
    $c->response->status(403);
    log_warn { "Access denied to " . $c->request->uri };
    $c->response->body("Access denied");
    return;
}

sub redirect_to_secure :Private {
    my ($self, $c) = @_;
    return if $c->request->secure;
    my $site = $c->stash->{site};
    if ($site->secure_site || $site->secure_site_only) {
        my $uri = $c->request->uri->clone;
        $uri->scheme('https');
        $c->response->redirect($uri);
        $c->detach();
    }
}

=head2 random

Path: /random

Get the a random text

=cut

sub random :Chained('/site') :Args(0) {
    my ($self, $c) = @_;
    if (my $text = $c->stash->{site}->titles->random_text) {
        $c->response->redirect($c->uri_for_action('/library/text', [$text->uri]));
    }
    else {
        $c->detach('/not_found');
    }
}

sub rss_xml :Chained('/site') :PathPart('rss.xml') :Args(0) {
    my ($self, $c) = @_;
    $c->detach('/feed/index');
}

sub favicon :Chained('/site') :PathPart('favicon.ico') :Args(0) {
    my ($self, $c) = @_;
    $c->detach('/sitefiles/local_files',
                ['favicon.ico']);
}

sub robots_txt :Chained('/site_no_auth') :PathPart('robots.txt') :Args(0) {
    my ($self, $c) = @_;
    my $robots = <<'ROBOTS';
User-agent: *
Disallow: /edit/
Disallow: /bookbuilder/
Disallow: /bookbuilder
Disallow: /search
Disallow: /git/
ROBOTS
    my $site = $c->stash->{site};
    if (!$site or $site->is_private) {
        $robots = "User-agent: *\nDisallow: /\n";
    }
    else {
        $robots .= "Sitemap: " . $c->uri_for_action('/sitemap_txt') . "\n";
    }
    $c->response->content_type('text/plain');
    $c->response->body($robots);
}

sub sitemap_txt :Chained('/site') :PathPart('sitemap.txt') :Args(0) {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};
    my @urls;
    my $base = $site->canonical_url_secure;
    foreach my $root ('library',
                      'opds',
                      'feed',
                      'category/topic',
                      'category/author') {
        push @urls, $base . '/' . $root;
    }
    my $texts = $site->titles->published_all
      ->search(undef, { order_by => [qw/f_class sorting_pos/] })->listing_tokens_plain;
    my $categories = $site->categories->active_only
      ->search(undef, { order_by => [qw/type sorting_pos/] })->listing_tokens;
    while (@$texts) {
        my $text = shift @$texts;
        push @urls, $base . $text->{full_uri};
    }
    while (@$categories) {
        my $cat = shift @$categories;
        push @urls, $base . $cat->{full_uri};
    }
    push @urls, '';
    $c->response->content_type('text/plain');
    $c->response->body(join("\n", @urls));
}

=head2 index

The root page (/) points to /library/ if there is no special/index

=cut

sub index :Chained('/site') :PathPart('') :Args(0) {
    my ( $self, $c ) = @_;
    # check if we have a special page named index
    my $nav = $c->stash->{navigation};
    my $target;
    my $site = $c->stash->{site};
    my $locale = $c->stash->{current_locale_code} || $site->locale;
    if ($site->multilanguage and
        (my $locindex = $site->titles->special_by_uri('index-' . $locale))) {
        $target = $c->uri_for($locindex->full_uri);
    }
    elsif (my $index = $site->titles->special_by_uri('index')) {
        $target = $c->uri_for($index->full_uri);
    }
    else {
        $target = $c->uri_for_action('/library/listing');
    }
    $c->res->redirect($target);
}

sub catch_all :Chained('/site') :PathPart('') Args {
    my ($self, $c, $try) = @_;
    my $fallback;
    if ($try) {
        my $try_uri = AmuseWikiFarm::Utils::Amuse::muse_naming_algo($try);
        my $query = { uri => $try_uri };
        if (my $site = $c->stash->{site}) {
            if (my $text = $site->titles->published_all
                ->search($query)->first) {
                $fallback = $text->full_uri;
            }
            elsif (my $cat = $site->categories->active_only
                   ->search($query)->first) {
                $fallback = $cat->full_uri;
            }
            elsif (my $red = $site->redirections
                   ->search($query)->first) {
                $fallback = $red->full_dest_uri;
            }
        }
    }
    if ($fallback) {
        $c->response->redirect($c->uri_for($fallback));
        $c->detach();
    }
    else {
        $c->detach('not_found');
    }
}

=head2 end

Attempt to render a view, if needed.

If the site has a theme, add that at the beginning of the TT's include
path.

=cut

sub end : ActionClass('RenderView') {
    my ($self, $c) = @_;

    # before passing the thing to the template, strip <> from page_title
    if ($c->stash->{page_title}) {
        $c->stash->{page_title} =~ s/<.*?>//g;
    }

    # be sure to always pass the current_locale_code and default to english
    unless ($c->stash->{current_locale_code}) {
        $c->stash(current_locale_code => 'en');
    }


    my $site = $c->stash->{site};
    return unless $site;

    if (my $theme = $site->theme) {
        die "Bad theme name!" unless $theme =~ m/^\w[\w-]+\w$/s;
        $c->stash->{additional_template_paths} =
          [$c->path_to(root => themes => $theme)];
    }
}

=head1 AUTHOR

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
