package AmuseWikiFarm::Controller::Admin;
use Moose;
with qw/AmuseWikiFarm::Role::Controller::Jobs/;

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;
use Regexp::Common qw/net/;
use AmuseWikiFarm::Utils::Paginator qw();

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

sub root :Chained('/site_user_required') :PathPart('admin') :CaptureArgs(0) {
    my ($self, $c) = @_;
    unless ($c->user_exists && $c->check_user_roles('root')) {
        $c->detach('/not_permitted');
        return;
    }
    $c->stash(full_page_no_side_columns => 1);
}

sub debug_site_id :Chained('root') :Args(0) {
    my ( $self, $c ) = @_;
    $c->response->body(join(" ",
                            $c->stash->{site}->id,
                            $c->stash->{site}->locale,
                           ));
}

sub debug_loc :Chained('root') :Args(0) {
    my ($self, $c) = @_;
    $c->response->content_type('text/plain');
    $c->stash(no_wrapper => 1);
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
    # given that we have HTML going in and going out, we need to
    # prevent chrome to complain.
    # https://stackoverflow.com/questions/43249998/chrome-err-blocked-by-xss-auditor-details
    $c->response->header('X-XSS-Protection', 0);
    my $check_config;
    if ($id) {
        if ($site = $c->model('DB::Site')->find($id)) {
            if (delete $params{edit_site}) {
                if (my $err = $site->update_from_params(\%params)) {
                    # probably the error will never get localized...
                    $c->flash(error_msg => $c->loc($err));
                }
                else {
                    $check_config = 1;
                }
            }
        }
    }
    elsif ($params{create_site} && $params{canonical}) {
        # here we accept 0 as prefix as well, but we warned
        if ($params{create_site} =~ m/\A([0-9a-z]{2,16})\z/ and
            $params{canonical}   =~ m/\A$RE{net}{domain}{-nospace}{-rfc1101}\z/) {
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
                log_info { "Created site $id, redirecting to $edit_link" };
                $c->response->redirect($edit_link);
                $c->detach();
                return;
            }
        }
        else {
            log_error { $params{canonical} . " doesn't match " .
                          $RE{net}{domain}{-nospace}{-rfc1101} };
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

    # if the site was edited, check and update the configs
    if ($check_config) {
        # check if the webserver needs a refresh
        my @all_sites = $c->model('DB::Site')->active_only->all;
        my $config_generator = $c->model('Webserver');
        if (my $refresh = $config_generator->generate_nginx_config(@all_sites)) {
            $c->stash(exec_as_root => $refresh);
        }
    }

    $c->stash(esite => $site);
    $c->stash(load_highlight => $site->use_js_highlight(1));
}

sub get_jobs :Chained('root') :PathPart('jobs') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $rs = $c->model('DB::Job');
    $c->stash(
              all_jobs => $rs,
              page_title => $c->loc('Jobs'),
             );
}

# chaining here in the role AmuseWikiFarm::Role::Controller::Jobs;

sub create_user :Chained('root') :PathPart('newuser') :Args(0) {
    my ($self, $c) = @_;
    my $params = $c->request->body_params;
    my $home = $c->uri_for_action('/admin/show_users');
    unless ($params->{create} && $params->{username}) {
        $c->response->redirect($home);
        return;
    }
    my $dumb_pass = rand(9999999) . '';
    my %insertion = (
                     active => 0,
                     password => $dumb_pass,
                     passwordrepeat => $dumb_pass,
                     username => $params->{username},
                    );
    my $users = $c->model('DB::User');
    my ($validated, @errors) = $users->validate_params(%insertion);
    if ($validated) {
        if ($users->find({ username => $validated->{username} })) {
            $c->flash(error_msg => $c->loc("Such an user already exists!"));
        }
        else {
            $validated->{created_by} = $c->user->get('username');
            my $user = $users->create($validated);
            $c->response->redirect($c->uri_for_action('/admin/show_user_details',
                                                      [ $user->id ]));
            return;
        }
    }
    elsif (@errors) {
        $c->flash(error_msg => join("\n", map { $c->loc($_) } @errors));
    }
    log_warn { "Validation failed" };
    $c->response->redirect($home);
}

sub users :Chained('root') :PathPart('users') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $users = $c->model('DB::User')->search({},
                                              {
                                               order_by => [qw/username/]
                                              });
    $c->stash(
              all_users => $users,
              page_title => $c->loc('Users'),
             );
}

sub show_users :Chained('users') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    return;
}

sub user_details :Chained('users') :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    if ($id =~ m/\A([0-9]+)\z/) {
        if (my $user = $c->stash->{all_users}->find($1)) {
            $c->stash(user => $user);
            return;
        }
        log_warn { "User $id not found" };
    }
    else {
        log_warn { "Garbage passed as id: $id" };
    }
    $c->detach('/not_found');
}

sub show_user_details :Chained('user_details') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    return;
}

sub edit_user_details :Chained('user_details') :PathPart('edit') :Args(0){
    my ($self, $c) = @_;
    # pick user from the stash
    my $user = $c->stash->{user};
    die "Shouldn't happen" unless $user;
    my $params = $c->request->body_params;
    my %updates;
    my @errors;
    if ($params->{update}) {
        if ($params->{password} || $params->{passwordrepeat}) {
            $updates{password} = $params->{password} || '';
            $updates{passwordrepeat} = $params->{passwordrepeat} || '';
        };
        if ($params->{email}) {
            $updates{email} = $params->{email};
        }
        $updates{active} = $params->{active};

        # validate
        my ($validated, @errors) = $c->stash->{all_users}
          ->validate_params(%updates);

        if ($validated) {
            # active flipping
            my $mail_required = 0;
            if (!$user->active and $validated->{active}) {
                $mail_required = 1;
            }

            $user->update($validated);
            my @roles;
            foreach my $role ($user->available_roles) {
                if ($params->{"role-$role"}) {
                    push @roles, { role => $role };
                }
            }
            $user->set_roles(\@roles);
            # and the sites
            my @sites;
            foreach my $site (map { $_->{id} } $user->available_sites) {
                if ($params->{"site-$site"}) {
                    push @sites, { id => $site };
                }
            }
            $user->set_sites(\@sites);
            if ($mail_required) {
                # TODO: send a mail like in C::User
            }
            $c->flash(status_msg => $c->loc('User [_1] updated', $user->username));
            $c->response->redirect($c->uri_for_action('/admin/show_users'));
            return;
        }
        if (@errors) {
            $c->flash(error_msg => join("\n", map { $c->loc($_) } @errors));
        }
    }
    $c->response->redirect($c->uri_for_action('/admin/show_user_details',
                                              [ $c->stash->{user}->id ]));
}

sub delete_user :Chained('user_details') :PathPart('delete') :Args(0) {
    my ($self, $c) = @_;
    if ($c->request->body_params->{delete}) {
        log_info { "Deleting user " . $c->stash->{user}->username };
        $c->flash(status_msg => $c->loc("User [_1] deleted", $c->stash->{user}->username));
        $c->stash->{user}->delete;
    }
    $c->response->redirect($c->uri_for_action('/admin/show_users'));
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
