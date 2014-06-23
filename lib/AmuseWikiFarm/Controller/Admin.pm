package AmuseWikiFarm::Controller::Admin;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Admin - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 auto

Grant access to root users only.

=cut

sub auto :Private {
    my ($self, $c) = @_;
    if ($c->user_exists && $c->check_user_roles('root')) {
        return 1;
    }
    else {
        $c->detach('/not_permitted');
        return;
    }
}

=head2 debug_site_id

Show the site id.

=cut

sub root :Chained('/') :PathPart('admin') :CaptureArgs(0) {
    my ($self, $c) = @_;
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

sub list :Chained('sites') :Args(0) {
    my ($self, $c) = @_;
    my $sites = delete $c->stash->{all_sites};
    $c->stash(page_title => $c->loc('All sites'),
              list => [ $sites->all ]);
}

sub edit :Chained('sites') :Args() {
    my ($self, $c, $id) = @_;
    my %params = %{ $c->request->params };
    my $site;
    my $listing_url = $c->uri_for_action('/admin/list');

    if ($id) {
        if ($site = $c->model('DB::Site')->find($id)) {
            if ($params{edit_site}) {
                # edit it...
            }
        }
    }
    elsif ($params{create_site}) {
        if ($params{create_site} =~ m/^([1-9a-z][0-9a-z]{1,15})$/) {
            $id = $1;
            if ($c->model('DB::Site')->find($id)) {
                $c->flash(error_msg => $c->loc('Site already exists'));
                $c->response->redirect($listing_url);
                $c->detach();
                return;
            }
            else {
                # creation
                $site = $c->model('DB::Site')->create({ id => $id });
            }
        }
        else {
            $c->flash(error_msg => $c->loc('Invalid name'));
            $c->response->redirect($listing_url);
            $c->detach();
            return;
        }

    }
    $site->discard_changes;
    $c->stash(esite => $site);
}

sub site_params_for_db :Private {
    my ($self, $params) = @_;
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
