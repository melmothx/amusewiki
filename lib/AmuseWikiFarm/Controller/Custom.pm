package AmuseWikiFarm::Controller::Custom;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Custom - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

use AmuseWikiFarm::Log::Contextual;
use File::Spec;

sub root :Chained('/site') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub custom :Chained('root') :PathPart('custom') :Args(1) {
    my ($self, $c, $file) = @_;
    log_debug { "Requested $file" };

    if (my $site = $c->stash->{site}) {
        my $site_id = $site->id;
        if (my $serve = $c->model('DB::JobFile')->find($file)) {
            log_debug { "Found $file in the db" };
            if ($serve->job->site_id eq $site_id) {
                log_debug { "$file ok, belongs to $site_id" };
                $c->stash(serve_static_file => $serve->path);
                $c->detach($c->view('StaticFile'));
                return;
            }
            else {
                log_error { "$file doesn't belong to $site_id" };
            }
        }
        else {
            log_error { "$file not found in the table" };
        }
        # LEGACY APPROACH: remove this block in 2016
        my $job_id;
        if ($file =~ m/\A([0-9]+)\.(pdf|epub|sl\.pdf)\z/) {
            $job_id = $1;
        }
        elsif ($file =~ m/\Abookbuilder-([0-9]+)\.zip\z/) {
            $job_id = $1;
        }
        if (defined $job_id) {
            if (my $job = $site->jobs->find($job_id)) {
                if ($job->task and $job->task eq 'bookbuilder') {
                    log_debug { "it looks like $file belongs to $job_id" };
                    my $path = File::Spec->rel2abs(File::Spec->catfile(bbfiles => $file));
                    log_debug { "Path is $path" };
                    if (-f $path) {
                        $c->stash(serve_static_file => $path);
                        $c->detach($c->view('StaticFile'));
                        return;
                    }
                }
            }
        }
    }
    $c->detach('/not_found');
}


=encoding utf8

=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
