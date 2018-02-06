package CatalystX::Session::Store::AMW;

use strict;
use Moose;
use MRO::Compat;
use namespace::clean -except => 'meta';
 
extends 'Catalyst::Plugin::Session::Store';

sub get_session_data {
    my ($c, @args) = @_;
    my $site = $c->stash->{site}
      or Catalyst::Exception->throw("site not present in the stash, cannot get the session");
    $site->amw_sessions->get_session_data($site->id, @args);
}
sub store_session_data {
    my ($c, @args) = @_;
    my $site = $c->stash->{site}
      or Catalyst::Exception->throw("site not present in the stash, cannot store the session");
    $site->amw_sessions->store_session_data($site->id, @args);
}
sub delete_session_data {
    my ($c, @args) = @_;
    my $site = $c->stash->{site}
      or Catalyst::Exception->throw("site not present in the stash, cannot delete the session");
    $site->amw_sessions->delete_session_data($site->id, @args);
}
sub delete_expired_sessions {
    my ($c, @args) = @_;
    my $site = $c->stash->{site}
      or Catalyst::Exception->throw("site not present in the stash, cannot delete expired sessions");
    $site->amw_sessions->delete_expired_sessions($site->id, @args);
}

__PACKAGE__->meta->make_immutable;

1;
