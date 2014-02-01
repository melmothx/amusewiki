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
if C<shared_template> is not set.

=cut

sub end : ActionClass('RenderView') {
    my ($self, $c) = @_;

    # TODO: probably better do in the view?
    # if it's not marked as a shared template, looks into the
    # include path and try to find the template.
    if ($c->stash->{template} && !$c->stash->{shared_template}) {
        my @paths = @{ $c->view('HTML')->config->{INCLUDE_PATH} };
        my $template_fullpath = catfile($c->stash->{site_id},
                                        $c->stash->{template});

        my $missing = 1;
        foreach my $path (@paths) {
            if (-f catfile($path, $template_fullpath)) {
                $missing = 0;
                $c->log->debug("Found $template_fullpath");
                last;
            }
        }
        if ($missing) {
            $c->log->debug("$template_fullpath not found, using one in default");
            $template_fullpath = catfile(default => $c->stash->{template});
        }

        $c->stash(template => $template_fullpath );
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
