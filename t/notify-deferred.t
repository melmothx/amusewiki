#!perl

use utf8;
use strict;
use warnings;

BEGIN {
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';
    $ENV{DBIX_CONFIG_DIR} = "t";
}


use Test::More tests => 8;
use File::Spec::Functions qw/catdir catfile/;
use AmuseWikiFarm::Schema;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use DateTime;
use Data::Dumper::Concise;
use Email::Sender::Simple;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0deferred2');
$site->update({
               mail_from => 'test@amusewiki.org',
               mail_notify => 'pippo@amusewiki.org',
               locale => 'it',
              });

my $text;
{
    my ($rev) = $site->create_new_text({
                                        title => 'Deferred',
                                        pubdate => DateTime->now->add(months => 1),
                                        textbody => 'Test',
                                       }, 'text');
    $rev->commit_version;
    $rev->publish_text;
    $text = $rev->title;
}

ok $text;
$text->is_deferred;
{
    my $f = $text->path_tiny;
    my $body = $f->slurp_utf8;
    $body =~ s/^#pubdate.*$//m;
    $f->spew_utf8($body);
}
$schema->resultset('Job')->delete;
$text->update({ pubdate => DateTime->now->subtract(days => 1) });
$schema->resultset('Job')->enqueue_global_job('hourly_job');

while (my $j = $schema->resultset('Job')->dequeue) {
    $j->dispatch_job;
    diag $j->logs;
}

$text = $text->get_from_storage;
ok !$text->is_deferred;

{
    my @mails = Email::Sender::Simple->default_transport->deliveries;
    ok (@mails == 2, "Found mail sent");
    ok scalar(@{$mails[1]->{successes}});
    my $body = $mails[1]->{email}->as_string;
    diag $body;
    like $body, qr{https://0deferred2.amusewiki.org/library/deferred};
    like $body, qr{pubblicato};
    like $body, qr{Data di pubblicazione};
    like $body, qr{Subject: /library/deferred: published};
}
