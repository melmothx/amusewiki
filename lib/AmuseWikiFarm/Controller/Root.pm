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

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body( $c->welcome_message );
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->detach('not_found');
}

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
    $c->log->debug("Site ID for $host is " . $site->id
                   . ", with locale " . $site->locale);

    $c->languages([ $site->locale ]);

    # stash the site object
    $c->stash(site => $site);
}

sub not_found :Global {
    my ($self, $c) = @_;
    $c->response->status(404);
    $c->log->debug("In the not_found!");
    $c->stash(error_msg => "Page not found!");
    $c->stash(template => "not_found.tt");
}

=head2 end

Attempt to render a view, if needed, prepending the stashed C<site_id>
if the file is present.

Routes that don't set the template in the stash will pick the default
without any checking.

The default wrapper is layout.tt. It's not overriden if no_wrapper is
set, otherwise the localized one is always preferred.

=cut

sub end : ActionClass('RenderView') {
    my ($self, $c) = @_;

    # TODO: probably better do in the view?
    # if it's not marked as a shared template, looks into the
    # include path and try to find the template.
    return unless $c->stash->{site};
    foreach my $k (qw/template wrapper/) {
        if ($k eq 'template') {
            next unless $c->stash->{$k};
        }
        elsif ($k eq 'wrapper') {
            next if $c->stash->{no_wrapper};
            if (!$c->stash->{$k}) {
                $c->stash($k, "layout.tt");
            }
        }

        my $override = $self->_find_template($c->stash->{site}->id,
                                             $c->stash->{$k},
                                             $c->view('HTML')->config->{INCLUDE_PATH});
        if ($override) {
            $c->log->debug("Found $k $override!");
            $c->stash($k, $override);
        }
    }
}

sub _find_template {
    my ($self, $id, $name, $paths) = @_;
    my $found;
    foreach my $path (@$paths) {
        my $try = catfile($path, $id, $name);
        if (-f $try) {
            $found = catfile($id, $name);
            last;
        }
    }
    return $found;
}


=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
