package AmuseWikiFarm::Controller::SiteAdmin;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;

=head1 NAME

AmuseWikiFarm::Controller::SiteAdmin - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub root :Chained('/site_user_required') :PathPart('site-admin') :CaptureArgs(0) {
    my ($self, $c) = @_;
    unless ($c->user_exists && $c->check_user_roles('admin')) {
        $c->detach('/not_permitted');
        return;
    }
    $c->stash(full_page_no_side_columns => 1);
}

sub users :Chained('root') :PathPart('users') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my @users;
    foreach my $u ($c->stash->{site}->users->all) {
        my %user = (
                    id => $u->id,
                    username => $u->username,
                    created_by => $u->created_by,
                    active => $u->active,
                    email => $u->email,
                    roles => join(' ', map { $_->role } $u->roles),
                   );

        # exactly one librarian role
        if ($user{roles} and $user{roles} eq 'librarian') {
            $user{can_be_deleted} = 1;
        }
        push @users, \%user;
    }
    Dlog_debug { "Users are $_" } \@users;
    $c->stash(
              all_users => \@users,
              page_title => $c->loc('Site users'),
             );
}

sub show_users :Chained('users') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(
              load_datatables => 1,
             );
}

sub delete_user :Chained('users') :PathPart('delete') :Args(1) {
    my ($self, $c, $uid) = @_;
    log_debug { "Requested $uid deletion" };
    if ($uid and $c->request->body_params->{delete}) {
        if (grep { $_->{can_be_deleted} and $uid eq $_->{id} }  @{ $c->stash->{all_users} }) {
            if (my $user = $c->stash->{site}->users->find($uid)) {
                $c->flash(status_msg => $c->loc("User [_1] deleted", $user->username));
                $user->delete;
            }
        }
        else {
            log_info { "User $uid cannot be deleted" };
        }
    }
    $c->response->redirect($c->uri_for_action('/siteadmin/show_users'));
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
