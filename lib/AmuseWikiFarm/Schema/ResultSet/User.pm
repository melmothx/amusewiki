package AmuseWikiFarm::Schema::ResultSet::User;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use Email::Valid;
use constant { MAXLENGTH => 255, MINPASSWORD => 7 };
use AmuseWikiFarm::Log::Contextual;
use Bytes::Random::Secure; # who knows how much is really secure, but hey
use Crypt::XkcdPassword;

=head1 NAME

AmuseWikiFarm::Schema::ResultSet::User - Users resultset

=head1 METHODS

=head2 validate_params(%params)

Return a validated hashrefs with these params: username, email,
password if the constraint passes.

Accepted paramaters:

=over 4

=item username

=item email

=item emailrepeat

=item password

=item passwordrepeat (mandatory if password is provided)

=item active

=back

Otherwise return undef and a list of errors.

No operation is done against the db.

=cut



sub validate_params {
    my ($self, %params) = @_;
    my @errors;
    my %validated;
    # first, check the length
    foreach my $k (keys %params) {
        if (defined($params{$k}) and
            length($params{$k}) > MAXLENGTH) {
            # $c->loc('Some fields are too long'));
            push @errors, 'Some fields are too long';
            last;
        }
    }
    if (@errors) {
        return undef, @errors;
    }
    if (exists $params{username}) {
        if ($params{username} and $params{username} =~ m/\A([0-9a-z]{2,50})\z/) {
            $validated{username} = $1;
        }
        else {
            # $c->loc('Invalid username');
            push @errors, 'Invalid username';
        }
    }

    if (exists $params{email}) {
        if (my $mail = Email::Valid->address($params{email})) {
            $validated{email} = $mail;
        }
        else {
            # $c->loc('Invalid email');
            push @errors, 'Invalid email';
        }

    }

    if (exists $params{password}) {
        if ($params{password}) {
            if ($params{passwordrepeat} and
                $params{password} eq $params{passwordrepeat}) {
                if (length($params{password}) > MINPASSWORD) {
                    $validated{password} = $params{password};
                }
                else {
                    # $c->loc('Password too short')
                    push @errors, 'Password too short';
                }
            }
            else {
                # $c->loc('Passwords do not match')
                push @errors, 'Passwords do not match';
            }
        }
        else {
            push @errors, 'Password too short';
        }
    }

    # asked for emailrepeat
    if (exists $params{emailrepeat}) {
        $params{emailrepeat} ||= '';
        if ($params{emailrepeat} ne $params{email}) {
            # $c->loc('Emails do not match'));
            push @errors, 'Emails do not match';
        }
    }

    if (exists $params{active}) {
        $validated{active} = $params{active} ? 1 : 0;
    }

    if (@errors) {
        return undef, @errors;
    }
    else {
        return \%validated;
    }
}

sub set_reset_token {
    my ($self, $email) = @_;
    log_info { "Reset token requested for $email" };
    my @out;
    if ($email and $email =~ m/\w/) {
        my $users = $self->search({ email => $email });
        my $random = Bytes::Random::Secure->new(NonBlocking => 1);
        while (my $user = $users->next) {
            my $now = time();
            if (!$user->reset_token or $user->reset_until < $now) {
                log_info { "Setting reset token to " . $user->username };
                $user->update({
                               reset_token => $random->bytes_hex(32),
                               reset_until => $now + (60 * 60),
                              });
                push @out, $user;
            }
        }
    }
    return @out;
}

sub reset_password {
    my ($self, $username, $token) = @_;
    return unless $username && $token;
    log_info { "Reset password requested for $username with token $token" };
    if (my $user = $self->search({
                                  username => $username,
                                  reset_token => $token,
                                  reset_until => { '!=' => undef },
                                 })->first) {
        my $now = time();
        log_info { "User $username found, trying to update password if " .
                     $user->reset_until . " > $now" };

        if ($user->reset_until > $now) {
            my $password = 'reset' .
              Bytes::Random::Secure->new(NonBlocking => 1)->bytes_hex(32);
            $user->password($password);
            $user->reset_token(undef);
            $user->reset_until(undef);
            $user->update;
            return $password;
        }
    }
    return;
}


1;
