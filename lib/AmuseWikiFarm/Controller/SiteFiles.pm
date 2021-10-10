package AmuseWikiFarm::Controller::SiteFiles;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;
use Path::Tiny ();

=head1 NAME

AmuseWikiFarm::Controller::SiteFiles - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut


=head2 root

Start of the chain

=head2 site_files

Matches /sitefiles/<site_id> and points to the static files shipped in the
repository: repo/<site_id>/site_files/*

You can avoid the db queries and the code overhead linking the local
files directory into root/repo/<site_id>

 # say we have "sandbox" as id
 mkdir -p root/local
 cd root/local
 ln -s ../../repo/sandbox/local/site_files sandbox

=cut



sub root :Chained('/site_no_auth') :PathPart('sitefiles') :CaptureArgs(1) {
    my ( $self, $c, $site_id ) = @_;
    # check if the site_id matches the stashed value
    if ($site_id ne $c->stash->{site}->id) {
        $c->detach('/not_found');
    }
}

sub local_files :Chained('root') :PathPart('') :Args(1) {
    my ($self, $c, $file) = @_;
    if (my $gfile = $c->stash->{site}->site_files->find({ file_name => $file })) {
        if ($gfile->is_public) {
            $c->stash(serve_static_file => $gfile->file_path);
            $c->detach($c->view('StaticFile'));
            return;
        }
    }
    $c->detach('/not_found');
}

sub public :Chained('/site_robot_index') :PathPart('p') :Args(1) {
    my ($self, $c, $file) = @_;
    my $site = $c->stash->{site};
    if (my $f = $site->public_files->find({ file_name => $file })) {
        $c->stash(serve_static_file => $f->file_path);
        $c->detach($c->view('StaticFile'));
        return;
    }
    elsif (my $html = $site->public_files->find({ file_name => "$file.html" })) {
        $c->stash(
                  html_source => Path::Tiny::path($html->file_path)->slurp_utf8,
                  template => 'html-body.tt',
                 );
    }
    else {
        $c->detach('/not_found');
    }
}


=encoding utf8

=head1 AUTHOR

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
