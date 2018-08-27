package AmuseWikiFarm::Schema::ResultSet::Site;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use Data::Dumper::Concise;
use AmuseWikiFarm::Log::Contextual;
use Path::Tiny;

=head1 NAME

AmuseWikiFarm::Schema::ResultSet::Site - Site resultset

=head1 METHODS

=head2 active_only

Return the active sites, ordered by id and with vhosts prefetched.

=cut

sub public_only {
    my ($self) = @_;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.mode" => [qw/blog modwiki openwiki/] });
}

sub active_only {
    my ($self) = @_;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.active" => 1 },
                         { order_by => [ "$me.id" ],
                           prefetch => 'vhosts' });
}

=head2 with_acme_cert

Return the sites with acme_certificate set to 1

=cut

sub with_acme_cert {
    my ($self) = @_;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.acme_certificate" => 1 });
}

=head2 check_and_update_acme_certificates($update, $verbose)

Check and update the acme certificates. If a true argument is passed,
the update is performed, otherwise just the check is done.

=cut

sub check_and_update_acme_certificates {
    my ($self, $update, $verbose) = @_;
    my @sites = $self->active_only->with_acme_cert->all;
    my $got = 0;
    log_debug { "Got " . scalar(@sites) . " sites with acme" };
    if (@sites) {
        require AmuseWikiFarm::Utils::LetsEncrypt;
        my $root = path(qw/ssl ACME_ROOT/);
        $root->mkpath unless $root->exists;
        foreach my $site (@sites) {
            if (my $canonical = $site->canonical) {
                log_debug {  "Checking $canonical" };
                my $directory = path('ssl', $canonical);
                $directory->mkpath unless $directory->exists;
                my $le = AmuseWikiFarm::Utils::LetsEncrypt
                  ->new(directory => "$directory",
                        root => "$root",
                        mailto => $site->mail_notify || 'root@' . $canonical,
                        names => [ $site->all_site_hostnames ],
                        staging => $ENV{AMW_LETSENCRYPT_STAGING} || 0,
                       );
                if ($le->live_cert_is_valid) {
                    log_info { $canonical . ' expires on ' . $le->live_cert_object->notAfter  };
                    if ($verbose) {
                        print $canonical . ' expires on ' . $le->live_cert_object->notAfter . "\n";
                    }
                }
                elsif ($le->self_check) {
                    log_info { "$canonical needs new certificate (and self-check looks good)!" };
                    print "$canonical needs new certificate (and self-check looks good)!\n" if $verbose;
                    if ($update) {
                        print "Requiring certificate for $canonical\n" if $verbose;
                        if ($le->process) {
                            warn "$canonical has new cert, please reload the webserver\n" if $verbose;
                            log_warn { "Retrieved new certificate for $canonical, please reload the webserver" };
                            $got++;
                        }
                        else {
                            warn "Failed to get certificate for $canonical\n" if $verbose;
                            Dlog_error { "Couldn't retrieve cert $_ " } $le;
                        }
                    }
                    else {
                        log_warn { "$canonical needs a new certificate, update was disabled!" };
                    }
                }
                else {
                    log_error { "Self-check failed for $canonical and cert is not valid!" };
                    warn "Self-check failed for $canonical and cert is not valid!\n" if $verbose;
                }
            }
            else {
                log_error { "Missing canonical (?) in " . $site->id };
            }
        }
    }
    return $got;
}

=head2 deserialize_site(\%data)

Input is supposed to be the hashref returned by
L<AmuseWikiFarm::Schema::Result::Site>'s C<serialize> method.

Create the site and set the various options passed, and return it.

=cut

sub site_serialize_related_rels {
    my @out= (
              [ vhosts          => undef, { order_by => [qw/name/]        } ],
              [ site_options    => undef, { order_by => [qw/option_name/] } ],
              [ legacy_links    => undef, { order_by => [qw/legacy_path/] } ],
              [ site_links      => undef, { order_by => [qw/url/]         } ],
              [ categories      => undef, { order_by => [qw/uri/]         } ],
              [ custom_formats  => undef, { order_by => [qw/format_name/] } ],
              [ redirections    => undef, { order_by => [qw/uri/]         } ],
             );
    return @out;
}

sub deserialize_site {
    my ($self, $hashref) = @_;
    my $guard = $self->result_source->schema->txn_scope_guard;
    die "Missing input" unless $hashref;
    my %external;
    foreach my $spec ($self->site_serialize_related_rels) {
        my ($method, @search_args) = @$spec;
        my $values = delete $hashref->{$method} || [];
        $external{$method} = $values if @$values;
    }
    my @users = @{ delete $hashref->{users} || [] };
    my $site = $self->update_or_create($hashref);

    # notably, tables without a non-auto PK, and where it makes sense
    # to ignore override existing values.
    my %clear = (
                 site_links => 1,
                );

    foreach my $method (sort keys %external) {
        if ($clear{$method}) {
            log_debug { "Clearing out existing records for $method" };
            $site->$method->delete;
        }
        Dlog_debug { "Updating *** $method *** $_" } $external{$method};

        foreach my $row (@{$external{$method}}) {
            my %todo;
            foreach my $k (keys %$row) {
                if (ref($row->{$k}) and ref($row->{$k}) eq 'ARRAY') {
                    $todo{$k} = delete $row->{$k};
                }
            }

            # print "Updating or creating $method\n";
            my $created = $clear{$method} ? $site->$method->create($row) : $site->$method->update_or_create($row);

            if (%todo) {
                Dlog_debug { "Recursively updating data found in $method $_" } \%todo;
                $created->discard_changes;
                foreach my $submethod (keys %todo) {
                    foreach my $subdata (@{$todo{$submethod}}) {
                        $created->$submethod->update_or_create($subdata);
                    }
                }
            }
        }
    }
    my @add = $site->users;
    foreach my $user (@users) {
        # can't be passed plainly because it's a many to many
        my $roles = delete $user->{roles};
        # search it.
        if (my $exists = $self->result_source->schema->resultset('User')->find({ username => $user->{username} })) {
            if (grep { $_->username eq $user->{username} } @add) {
                print "User $user->{username} already present and belongs to the site\n";
            }
            else {
                print $exists->username . " already exists, adding it to the site\n";
                push @add, $exists;
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
