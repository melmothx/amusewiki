use strict;
use warnings;
use utf8;
use Test::More tests => 1;
use Path::Tiny;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0farsi0';
my $site = create_site($schema, $site_id);
$site->update({ locale => 'fa' });
$site->multilanguage('en fa');

my $body = path("t/files/rtl.html");

my ($rev, $error) = $site->create_new_text({
                                            title => 'x',
                                            lang => 'fa',
                                            uri => 'check-right',
                                            fileupload => "t/files/rtl.html",
                                           }, 'text');
diag $rev->muse_body;
unlike $rev->muse_body, qr{</?right>};

