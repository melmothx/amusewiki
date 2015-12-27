package AmuseWikiFarm::Schema::ResultSet::Site;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use Data::Dumper;

=head2 active_only

Return the active sites, ordered by id and with vhosts prefetched.

=cut

sub active_only {
    my ($self) = @_;
    return $self->search({ active => 1 },
                         { order_by => [qw/id/],
                           prefetch => 'vhosts' });
}

=head2 deserialize_site(\%data)

Input is supposed to be the hashref returned by
L<AmuseWikiFarm::Schema::Result::Site>'s C<serialize> method.

Create the site and set the various options passed, and return it.

=cut

sub deserialize_site {
    my ($self, $hashref) = @_;
    my $guard = $self->result_source->schema->txn_scope_guard;
    die "Missing input" unless $hashref;
    my %external;
    foreach my $method (qw/vhosts site_options site_links categories redirections/) {
        $external{$method} = delete $hashref->{$method} || [];
    }
    my @users = @{ delete $hashref->{users} || [] };
    my $site = $self->update_or_create($hashref);
    foreach my $method (sort keys %external) {
        # print "Updating *** $method ***\n" . Dumper([@{$external{$method}}]);
        foreach my $row (@{$external{$method}}) {
            my %todo;
            foreach my $k (keys %$row) {
                if (ref($row->{$k}) and ref($row->{$k}) eq 'ARRAY') {
                    $todo{$k} = delete $row->{$k};
                }
            }
            my $created = $site->$method->update_or_create($row);
            foreach my $submethod (keys %todo) {
                foreach my $subdata (@{$todo{$submethod}}) {
                    $created->$submethod->update_or_create($subdata);
                }
            }
        }
    }
    my @add = $site->users;
    foreach my $user (@users) {
        my $roles = delete $user->{roles};
        # search it.
        if (my $exists = $self->result_source->schema->resultset('User')->find({ username => $user->{username} })) {
            if (grep { $_->username eq $user->{username} } @add) {
                print "User $user->{username} already in\n";
            }
            else {
                print $exists->username . " already exists, not adding it to the site\n";
                # push @add, $exists;
            }
        }
        else {
            my $newuser = $self->result_source->schema->resultset('User')->create($user);
            print "Creating new user $user->{username}\n";
            $newuser->set_password_hash($user->{password});
            $newuser->set_roles($roles);
            push @add, $newuser;
        }
    }
    $site->set_users(\@add);
    $guard->commit;
    $site->discard_changes;
    return $site;
}

1;
