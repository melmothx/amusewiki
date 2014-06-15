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

    # set the localization
    $c->languages([ $site->locale ]);

    # stash the site object
    $c->stash(site => $site);

    my @related = $site->related_sites;
    my @specials = $site->special_list;
    for my $sp (@specials) {
        my $uri = $sp->{uri};
        $sp->{special_uri} = $uri;
        $sp->{uri} = $c->uri_for_action('/library/special', [ $uri ]);
        $sp->{active} = ($c->request->uri eq $sp->{uri});
    }

    # let's assume related will return self, and special index
    if (@related > 1 or @specials > 1) {
        $c->stash(navigation => { projects => \@related,
                                  specials => \@specials });
    }
    return 1;
}

sub not_found :Global {
    my ($self, $c) = @_;
    $c->response->status(404);
    $c->log->debug("In the not_found!");
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
    if (my $index = $c->stash->{site}->titles->special_by_uri('index')) {
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
