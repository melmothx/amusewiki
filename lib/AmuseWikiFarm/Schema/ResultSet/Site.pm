package AmuseWikiFarm::Schema::ResultSet::Site;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use Data::Dumper;

=head2 deserialize_site(\%data)

Input is supposed to be the hashref returned by
L<AmuseWikiFarm::Schema::Result::Site>'s C<serialize> method.

Create the site and set the various options passed, and return it.

=cut

sub deserialize_site {
    my ($self, $hashref) = @_;
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
    foreach my $user (@users) {
        my $roles = delete $user->{roles};
        # search it.
        my @add;
        if (my $exists = $self->result_source->schema->resultset('User')->find({ username => $user->{username} })) {
            push @add, $exists;
        }
        else {
            my $newuser = $self->result_source->schema->resultset('User')->create($user);
            $newuser->set_password_hash($user->{password});
            $newuser->set_roles($roles);
            push @add, $newuser;
        }
    }
    $site->set_users(\@users);
    $site->discard_changes;
    return $site;
}

1;
