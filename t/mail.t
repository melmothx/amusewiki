#!perl

use utf8;
use strict;
use warnings;

BEGIN { $ENV{EMAIL_SENDER_TRANSPORT} ||= 'Test' }

use Test::More tests => 7;
use AmuseWikiFarm::Utils::Mailer;
use Data::Dumper;

my $mailer = AmuseWikiFarm::Utils::Mailer->new(mkit_location => 't/mkits');

ok($mailer);
ok($mailer->transport);
$mailer->send_mail(test => {
                            from => "Mić <me\@localhost>",
                            to => "Mać <me\@localhost>",
                            cc => '',
                            subject => 'testè',
                            test => 'Mić Mać Đoè'
                           });

{
    my @mails = Email::Sender::Simple->default_transport->deliveries;
    my $sent = shift @mails;
    ok ($sent, "Email sent") and diag $sent->{email}->as_string;
    my $body = $sent->{email}->as_string;
    ok ($body);
    like ($body, qr/Hello there Mi=C4=87 Ma=C4=87 =C4=90o=C3=A8/);
    like ($body, qr/To: =\?UTF-8\?B\?TWHEhw==\?= <me\@localhost>/);
    like ($body, qr/From: =\?UTF-8\?B\?TWnEhw==\?= <me\@localhost>/);

}






