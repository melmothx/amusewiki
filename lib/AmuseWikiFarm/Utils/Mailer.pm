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
use LWP::UserAgent;

has mkit_location => (is => 'ro',
                      isa => 'Str',
                      required => 1);

has telegram_bot_token => (is => 'ro', isa => 'Str', required => 0);
has telegram_chat_id => (is => 'ro', isa => 'Str', required => 0);

sub send_mail {
    my ($self, $mkit, $tokens) = @_;
    die "Missing arguments to sendmail!" unless $mkit && $tokens;
    my $path = path($self->mkit_location, $mkit);
    if ($path->exists) {
        log_debug { "Using $path for mkit" };
    }
    else {
        log_error { "$mkit doesn't exist in $path" };
        return 0;
    }
    my $ok;
    try {
        my $kit = Email::MIME::Kit->new({ source => "$path" });
        my $email = $kit->assemble($tokens);
        if (defined $tokens->{cc} && !$tokens->{cc}) {
            $email->header_set('cc');
        }
        if ($tokens->{from} and $tokens->{to}) {
            sendmail($email);
            log_info { "Email sent with $mkit" };
            $ok = 1;
        }
        $self->send_other_notifications($mkit, $email);
    } catch {
        my $error = $_;
        Dlog_error { "Mailing via $mkit for $_ failed: $error" } $tokens;
        $ok = 0;
    };
    return $ok;
}

sub send_other_notifications {
    my ($self, $mkit, $email) = @_;
    my %telegram = (
                    generic => 1,
                    commit => 1,
                    git_action => 1,
                    git_conflict => 1,
                    newtext => 1,
                    publish => 1,
                   );
    if ($telegram{$mkit}) {
        if (my $token = $self->telegram_bot_token) {
            try {
                if (my $body = $email->body_str) {
                    my $subject = $email->header_str('Subject');
                    my $text = join("\n\n", grep { $_ }  ($body, $subject));
                    log_debug { "Telegram text is $text" };
                    my $ua = LWP::UserAgent->new(timeout => 30,
                                                 agent => "amusewiki-notifications/1.0"
                                                );
                    my $url = "https://api.telegram.org/bot${token}/sendMessage";
                    foreach my $chat_id (grep { /\w/ } split(/[\s,]+/, $self->telegram_chat_id)) {
                        log_debug { "Sending Telegram notification" };
                        $ua->post($url,
                                  {
                                   chat_id => $chat_id,
                                   text => $text,
                                   disable_web_page_preview => 1,
                                   disable_notification     => 1,
                                   parse_mode               => 'Markdown',
                                  });
                    }
                }
            }
            catch {
                my $error = $_;
                log_error { "Telegram notification for $mkit failed: $error" };
            };
        }
    }
}


__PACKAGE__->meta->make_immutable;

1;
