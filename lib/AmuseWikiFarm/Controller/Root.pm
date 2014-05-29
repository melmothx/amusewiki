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

    # set the localization
    $c->languages([ $site->locale ]);

    # stash the site object
    $c->stash(site => $site);

    my @related = $site->related_sites;
    my @specials = $site->special_list;
    for my $sp (@specials) {
        my $uri = $sp->{uri};
        $sp->{special_uri} = $uri;
        $sp->{uri} = $c->uri_for_action('special/display', [ $uri ]);
    }

    if (@related || @specials) {
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
    $c->log->debug("denied");
    unless ($c->stash->{error_msg}) {
        $c->stash(error_msg => $c->loc("Access denied!"));
    }
    $c->stash(template => "error.tt");
}

=head2 index

The root page (/) points to /library/index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    # check if we have a special page named index
    my $nav = $c->stash->{navigation};
    if (my $index = $c->stash->{site}->titles->special_by_uri('index')) {
        $c->res->redirect($c->uri_for_action('/special/display', [ 'index' ]));
        $c->detach();
        return;
    }
    $c->detach('/library/index');
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

    my $site = $c->stash->{site};
    die "No site found?" unless $site;
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
