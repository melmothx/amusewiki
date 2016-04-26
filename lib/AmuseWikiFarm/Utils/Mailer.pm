package AmuseWikiFarm::Utils::Mailer;

use strict;
use warnings;
use Moose;
use namespace::autoclean;

use AmuseWikiFarm::Log::Contextual;
use Email::Sender::Simple qw/sendmail/;
use Email::MIME::Kit;
use Module::Load;
use Path::Tiny;
use Try::Tiny;

has mkit_location => (is => 'ro',
                      isa => 'Str',
                      required => 1);

has mailer => (is => 'ro',
               isa => 'Str',
               default => sub { 'sendmail' },
              );

has mailer_args => (is => 'ro',
                    isa => 'HashRef',
                    default => sub { +{} },
                   );

has transport => (is => 'ro',
                  lazy => 1,
                  builder => '_build_transport');

sub _build_transport {
    my $self = shift;
    my $class = ucfirst($self->mailer);
    if ($class !~ /^Email::Sender::Transport::/ ) {
        $class = "Email::Sender::Transport::$class";
    }
    load $class;
    Dlog_info { "Loading $class as transport with $_" } $self->mailer_args;
    return $class->new($self->mailer_args);
}


sub send_mail {
    my ($self, $mkit, $tokens) = @_;
    die "Missing arguments to sendmail!" unless $mkit && $tokens;
    my $path = path($self->mkit_location, $mkit);
    log_debug { "Using $path for mkit" };
    my $ok;
    try {
        my $kit = Email::MIME::Kit->new({ source => "$path" });
        my $email = $kit->assemble($tokens);
        if (defined $tokens->{cc} && !$tokens->{cc}) {
            $email->header_set('cc');
        }
        sendmail($email, { transport => $self->transport });
        log_info { "Email sent with $mkit" };
        $ok = 1;
    } catch {
        my $error = $_;
        Dlog_error { "Mailing via $mkit for $_ failed: $error" } $tokens;
        $ok = 0;
    };
    return $ok;
}


__PACKAGE__->meta->make_immutable;

1;
