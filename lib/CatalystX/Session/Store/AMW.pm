package CatalystX::Session::Store::AMW;

use strict;
use Moose;
use MRO::Compat;
use namespace::clean -except => 'meta';
 
extends 'Catalyst::Plugin::Session::Store';

use AmuseWikiFarm::Log::Contextual;

sub _session_amw_resultset {
    my ($c) = @_;
    if (my $site = $c->stash->{site}) {
        return $site->amw_sessions;
    }
    else {
        Catalyst::Exception->throw("site not present in the stash, cannot use the session");
    }
}

sub get_session_data {
    shift->_session_amw_resultset->get_session_data(@_);
}
sub store_session_data {
    shift->_session_amw_resultset->store_session_data(@_);
}
sub delete_session_data {
    shift->_session_amw_resultset->delete_session_data(@_);
}
sub delete_expired_sessions {
    shift->_session_amw_resultset->delete_expired_sessions(@_);
}

__PACKAGE__->meta->make_immutable;

1;
