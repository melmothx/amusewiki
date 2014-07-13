package AmuseWikiFarm::Controller::Root;
use Moose;
use namespace::autoclean;
use File::Spec::Functions qw/catfile/;
BEGIN { extends 'Catalyst::Controller' }

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

=head2 auto

Root auto methods sets the site code C<site_id> in the stash, for
farming purposes, defaulting to C<default>.

=cut

sub auto :Private {
    my ($self, $c) = @_;

    # catch the host. ->uri is an URI object, as per doc.
    my $host = $c->request->uri->host;

    # lookup in the db
    my $vhost = $c->model('DB::Vhost')->find($host);
    unless ($vhost) {
        $c->detach('not_found');
    }

    my $site = $vhost->site;
    return unless $site;
    $c->log->debug("Site ID for $host is " . $site->id
                   . ", with locale " . $site->locale);


    # this means some fucker reused a cookie from another site to gain
    # access to this. A bit unlikely, but better now than later.
    if ($c->user_exists and ($c->session->{site_id} ne $site->id)) {
        $c->log->error("Session stealing from " . $c->req->address . " on " .
                       localtime());
        $c->delete_session;
        $c->detach('/not_permitted');
        return;
    }

    # stash the site object
    $c->stash(site => $site);
    my $locale = $site->locale;

    if ($site->multilanguage) {
        if (my $user_locale = $c->session->{user_locale}) {
            if (my $language = $site->known_langs->{$user_locale}) {
                $c->log->debug("Language is $language");
                # validated by now
                $locale = $user_locale;
            }
        }
    }
    $c->stash(current_locale_code => $locale,
              current_locale_name => $site->known_langs->{$locale},
             );
    # set the localization
    $c->languages([ $locale ]);



    my @related = $site->other_sites;
    my @specials = $site->special_list;
    for my $sp (@specials) {
        my $uri = $sp->{uri};
        $sp->{special_uri} = $uri;
        $sp->{uri} = $c->uri_for_action('/library/special', [ $uri ]);
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

sub not_found :Global {
    my ($self, $c) = @_;
    $c->stash(please_index => 0);
    $c->response->status(404);
    $c->log->debug("In the not_found!");


    # last chance: look into the redirections if we have a type and an uri,
    # set in C::Library or C::Category
    if (my $f_class = $c->stash->{f_class}) {
        if (my $uri = $c->stash->{uri}) {
            if (my $red = $c->stash->{site}->redirections->find({
                                                                 type => $f_class,
                                                                 uri => $uri
                                                                })) {
                $c->response->redirect($c->uri_for($red->full_dest_uri));
                $c->detach();
                return;
            }
        }
    }
    $c->stash(error_msg => $c->loc("Page not found!"));
    $c->stash(template => "error.tt");
}

sub not_permitted :Global {
    my ($self, $c) = @_;
    $c->response->status(403);
    $c->log->error("Access denied");
    $c->response->body("Access denied");
    return;
}

=head2 random

Path: /random

Get the a random text

=cut

sub random :Global :Args(0) {
    my ($self, $c) = @_;
    if (my $text = $c->stash->{site}->titles->random_text) {
        $c->response->redirect($c->uri_for_action('/library/text', [$text->uri]));
    }
    else {
        $c->detach('/not_found');
    }
}


=head2 index

The root page (/) points to /library/ if there is no special/index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    # check if we have a special page named index
    my $nav = $c->stash->{navigation};
    my $target;
    my $site = $c->stash->{site};
    my $locale = $c->stash->{current_locale_code} || $site->locale;

    if (my $locindex = $site->titles->special_by_uri('index-' . $locale)) {
        $target = $c->uri_for($locindex->full_uri);
    }
    elsif (my $index = $site->titles->special_by_uri('index')) {
        $target = $c->uri_for($index->full_uri);
    }
    else {
        $target = $c->uri_for_action('/library/regular_list_display');
    }
    $c->res->redirect($target);
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->detach('not_found');
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

    my $site = $c->stash->{site};
    return unless $site;

    if (my $theme = $site->theme) {
        die "Bad theme name!" unless $theme =~ m/^\w[\w-]+\w$/s;
        $c->stash->{additional_template_paths} =
          [$c->path_to(root => themes => $theme)];
    }
}

=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
