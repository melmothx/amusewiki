#!perl

use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use Test::More tests => 24;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Archive::BookBuilder;
use Data::Dumper::Concise;
use AmuseWikiFarm::Schema;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Path::Tiny;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0bbcli0');
$site->update({ logo => 'logo-yu.pdf' });
{
    my ($rev) = $site->create_new_text({
                                        title => 'test',
                                        uri => 'test',
                                        textbody => '<h3>1</h3><p>hello there</p><h3>2</h3><h3>3</h3>',
                                       }, 'text');
    $rev->edit($rev->muse_body . "\n; :c55556: \\vskip 3cm\n");
    $rev->commit_version;
    $rev->publish_text;
}


{
    my $bb = AmuseWikiFarm::Archive::BookBuilder->new(centerchapter => 1,
                                                      site => $site,
                                                      imposed => 1,
                                                      centersection => 0);
    diag Dumper({ $bb->compiler_options });
    diag Dumper({ $bb->imposer_options });
    my %opts = $bb->compiler_options;
    ok $opts{extra}{tex_emergencystretch};
    is $opts{extra}{division}, $bb->division;
    is $opts{extra}{logo}, 'logo-yu.pdf';
    ok $opts{pdf};
    ok $opts{tex};
    # diag Dumper($bb->as_job);
    my $cli = $bb->as_cli;
    like $cli, qr{fontsize=10};
    like $cli, qr{pdf-impose};
    like $cli, qr{--schema 2up};
    diag $bb->as_cli; 
}

my $job_id = 55555;
foreach my $spec ({
                   unbranded => 1
                  },
                  {
                   imposed => 1,
                  }) {
    $job_id++;
    my $bb = AmuseWikiFarm::Archive::BookBuilder->new(centerchapter => 1,
                                                      site => $site,
                                                      coverfile => 't/prova.png',
                                                      paper_height => '231',
                                                      paper_width => '199',
                                                      job_id => $job_id,
                                                      centersection => 0,
                                                      custom_format_id => "c" . $job_id,
                                                      %$spec,
                                                     );
    $bb->add_text('test');
    diag $bb->compile;
    my $cli = $bb->as_cli;
    like $cli, qr/\Q--extra papersize=199mm:231mm\E/;
    my $bbfile = path(bbfiles => "bookbuilder-${job_id}.zip");
    ok $bbfile->exists;
    my $extractor = Archive::Zip->new;
    ok ($extractor->read("$bbfile") == AZ_OK, "Zip can be read");
    diag Dumper([ $extractor->members ]);
    my ($tex) = $extractor->membersMatching(qr{\.tex$});
    ok $tex;
    my $tex_body = $extractor->contents($tex->fileName);
    like $tex_body, qr/199mm:231mm/;
    diag $tex_body;
    like $tex_body, qr/hello there/;
    my $site_name = $site->canonical;
    if ($spec->{unbranded}) {
        unlike $tex_body, qr/$site_name/;
    }
    else {
        like $tex_body, qr/$site_name/;
    }
    if ($job_id == 55556) {
        like $tex_body, qr/^\\vskip 3cm/m;
    }
    else {
        like $tex_body, qr/backslash\{\}vskip 3cm/m;
    }
    $bbfile->remove;
}
