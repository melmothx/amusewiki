package AmuseWikiFarm::Controller::Admin;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Admin - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 root

Grant access to root users only.

=cut

=head2 debug_site_id

Show the site id.

=cut

sub root :Chained('/site') :PathPart('admin') :CaptureArgs(0) {
    my ($self, $c) = @_;
    unless ($c->user_exists && $c->check_user_roles('root')) {
        $c->detach('/not_permitted');
    }
}

sub debug_site_id :Chained('root') :Args(0) {
    my ( $self, $c ) = @_;
    $c->response->body(join(" ",
                            $c->stash->{site}->id,
                            $c->stash->{site}->locale,
                           ));
}


sub sites :Chained('root') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $rs = $c->model('DB::Site')->search({},
                                           { order_by => [qw/id/] });
    $c->stash(all_sites => $rs);
}

sub list :Chained('sites') :PathPart('') :Args(0)  {
    my ($self, $c) = @_;
    my $sites = delete $c->stash->{all_sites};
    $c->stash(page_title => $c->loc('All sites'),
              list => [ $sites->all ]);
}

sub edit :Chained('sites') :PathPart('edit') :Args() {
    my ($self, $c, $id) = @_;
    my %params = %{ $c->request->body_parameters };
    my $site;
    my $listing_url = $c->uri_for_action('/admin/list');

    if ($id) {
        if ($site = $c->model('DB::Site')->find($id)) {
            if (delete $params{edit_site}) {
                if (my $err = $site->update_from_params(\%params)) {
                    # probably the error will never get localized...
                    $c->flash(error_msg => $c->loc($err));
                }
            }
        }
    }
    elsif ($params{create_site} && $params{canonical}) {
        # here we accept 0 as prefix as well, but we warned
        if ($params{create_site} =~ m/^([0-9a-z]{2,16})$/ and
            $params{canonical}   =~ m/^[0-9a-z]+(\.[0-9a-z]+){2,4}$/) {
            $id = $params{create_site};
            if ($c->model('DB::Site')->find($id)) {
                $c->flash(error_msg => $c->loc('Site already exists'));
                $c->response->redirect($listing_url);
                $c->detach();
                return;
            }
            else {
                # creation
                my $site_creation = {
                                     id => $id,
                                     canonical => $params{canonical},
                                    };
                $site = $c->model('DB::Site')->create($site_creation);
                $site->initialize_git;
                my $edit_link = $c->uri_for_action('/admin/edit', $id);
                $c->log->info("Created site $id, redirecting to $edit_link");
                $c->response->redirect($edit_link);
                $c->detach();
                return;
            }
        }
        else {
            $c->flash(error_msg => $c->loc('Invalid name'));
            $c->response->redirect($listing_url);
            $c->detach();
            return;
        }
    }
    else {
        $c->response->redirect($listing_url);
        return;
    }
    $site->discard_changes;
    $c->stash(esite => $site);
}

sub get_jobs :Chained('root') :PathPart('jobs') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $rs = $c->model('DB::Job')->search({},
                                          { order_by => { -desc => [qw/completed/] } });
    $c->stash(
              all_jobs => $rs,
              page_title => $c->loc('Jobs'),
             );
}

sub jobs :Chained('get_jobs') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    my $all = delete $c->stash->{all_jobs};
    $c->stash(jobs => [ $all->all ]);
}

sub delete_job :Chained('get_jobs') :PathPart('delete') :Args(0) {
    my ($self, $c) = @_;
    if (my $id = $c->request->body_parameters->{job_id}) {
        if (my $job = $c->stash->{all_jobs}->find($id)) {
            $job->delete;
            $c->flash(status_msg => $c->loc("Job deleted"));
        }
        else {
            $c->flash(error_msg => $c->loc("Job not found"));
        }
    }
    else {
        $c->flash(error_msg => $c->loc("Bad request"));
    }
    $c->response->redirect($c->uri_for_action('/admin/jobs'));
    return;

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
