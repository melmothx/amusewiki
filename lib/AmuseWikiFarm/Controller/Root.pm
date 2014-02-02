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
    $c->response->body( 'Page not found' );
    $c->response->status(404);
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
    my $site = $c->model('DB::Site')->find($host);
    my $site_id = 'default';
    my $locale  = 'en';
    if ($site) {
        $site_id = $site->site_id;
        $locale  = $site->locale;
    }
    # log for good measure
    $c->log->debug("Site ID for $host is $site_id, with locale $locale");

    # stash the site_id
    $c->stash(
              site_id => $site_id,
              locale  => $locale,
             );
}



=head2 end

Attempt to render a view, if needed, prepending the stashed C<site_id>
if the file is present.

Routes that don't set the template in the stash will pick the default
without any checking.

=cut

sub end : ActionClass('RenderView') {
    my ($self, $c) = @_;

    # TODO: probably better do in the view?
    # if it's not marked as a shared template, looks into the
    # include path and try to find the template.
    if ($c->stash->{template}) {
        my $override = $self->_find_template($c->stash->{site_id},
                                             $c->stash->{template},
                                             $c->view('HTML')->config->{INCLUDE_PATH});
        if ($override) {
            $c->log->debug("Found $override!");
            $c->stash(template => $override );
        }
    }
}

sub _find_template {
    my ($self, $id, $name, $paths) = @_;
    my $found;
    foreach my $path (@$paths) {
        my $try = catfile($path, $id, $name);
        if (-f $try) {
            $found = $try;
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
