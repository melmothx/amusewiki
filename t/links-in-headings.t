#!perl

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use strict;
use warnings;
use utf8;
use Test::More tests => 6;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site run_all_jobs/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0break0');
$site->update({pdf => 1, a4_pdf => 1, lt_pdf => 1});
$site->check_and_update_custom_formats;
my $git = $site->git;
ok ((-d $site->repo_root), "test site created");
my ($revision) = $site->create_new_text({ uri => 'first-testx',
                                          title => 'Hello',
                                          lang => 'hr',
                                          textbody => 'bla',
                                        }, 'text');
my $test_body =<<'MUSE';

* [[https://amusewiki.org][*hello* <em>there</em>]]

** This was an error
[[https://amusewiki.org][hello]]

*** [[https://amusewiki.org]] [[https://amusewiki.org][test]]

**** [[https://amusewiki.org][*hello*]]

***** [[https://amusewiki.org]]

Bla bal

MUSE

$revision->edit($revision->muse_body . $test_body);
# diag $revision->muse_body;

$revision->commit_version;
$revision->publish_text;
my $title = $revision->title;
$title->discard_changes;
is $title->status, "published", "Title status now is published";
like $title->html_body, qr{\[\[https.+\]\]}, "Found the hyperlinks";
run_all_jobs($schema);
foreach my $ext (qw/pdf a4.pdf lt.pdf/) {
    ok (-f $title->filepath_for_ext($ext), "Found " . $title->filepath_for_ext($ext));
}



