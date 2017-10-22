#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 85;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site run_all_jobs/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;
use DateTime;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0nofinal0';
my $site = create_site($schema, $site_id);
$site->update({
               secure_site => 0,
               tex => 1,
               pdf => 1,
              });

$site->check_and_update_custom_formats;


my ($with_toc, $no_toc);
{
    my ($rev, $err) =  $site->create_new_text({ author => 'pinco',
                                                title => 'pallino no toc',
                                                lang => 'en',
                                              }, 'text');
    die $err if $err;
    $rev->edit($rev->muse_body . "\n\n some more text for the masses\n");
    $rev->commit_version;
    $no_toc = $rev->publish_text;
}
{
    my ($rev, $err) =  $site->create_new_text({ author => 'pinco',
                                                title => 'pallino with toc',
                                                lang => 'en',
                                              }, 'text');
    die $err if $err;
    $rev->edit($rev->muse_body . "\n\n** Chapter\n\n some more text for the masses\n");
    $rev->commit_version;
    $with_toc = $rev->publish_text;
}
diag $with_toc;
diag $no_toc;

run_all_jobs($schema);

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my %toc = (
           $with_toc => 1,
           $no_toc => 0,
          );

foreach my $uri (keys %toc) {
    $mech->get_ok($uri);
    $mech->get_ok($uri . '.pdf');
    $mech->get_ok($uri . '.tex');
    is_book($mech);
}

ok !$site->nocoverpage;

my @cfs;

{
    $mech->get('/login');
    $mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
    $mech->get('/user/site');
    $mech->submit_form(with_fields => { nocoverpage => 1 },
                       button => 'edit_site');

    foreach my $nc (0..2) {
        $mech->get_ok('/settings/formats');
        my %fields = (
                      format_name => 'nocoverpage-' . $nc,
                     );
        $mech->submit_form(with_fields => { %fields });
        if ($nc == 1) {
            $fields{nocoverpage} = 1;
        }
        elsif ($nc == 2) {
            $fields{coverpage_only_if_toc} = 1;
        }
        push @cfs, \%fields;
        ok($mech->submit_form(with_fields => {
                                           format => 'pdf',
                                           %fields,
                                          },
                           button => 'update',
                          ));
    }
}

ok $site->discard_changes->nocoverpage, "Option picked up" or die;

# rebuild as in the upgrade script
my $older_than  = DateTime->new(year => 2017,
                                month => 4,
                                day => 1)->epoch;


foreach my $s ($schema->resultset('Site')->search({
                                                   nocoverpage => 1,
                                                   id => $site->id, # not in the upgrade, obviously
                                                  })) {
    foreach my $text ($s->titles->status_is_published_or_deferred
                      ->search({ f_timestamp_epoch => { '>' => $older_than } })) {
        $s->jobs->rebuild_add({ id => $text->id });;
    }
}

while (my $job = $site->jobs->dequeue) {
    $job->dispatch_job;
    is $job->status, 'completed';
    diag $job->logs;
}

diag Dumper(\@cfs);

foreach my $uri (keys %toc) {
    $mech->get_ok($uri);
    $mech->get_ok($uri . '.pdf');
    $mech->get_ok($uri . '.tex');
    # has toc?
    if ($toc{$uri}) {
        is_book($mech);
    }
    else {
        is_article($mech);
    }
    foreach my $cf_spec (@cfs) {
        my $cf = $site->custom_formats->single({ format_name => $cf_spec->{format_name} });
        ok $cf;
        $mech->get_ok($uri . '.' . $cf->extension);
        $mech->get_ok($uri . '.' . $cf->tex_extension);
        # this is not conditional. It will always be an article
        if ($cf->bb_nocoverpage) {
            is_article($mech);
        }
        elsif ($cf->bb_coverpage_only_if_toc) {
            if ($toc{$uri}) {
                is_book($mech);
            }
            else {
                is_article($mech);
            }
        }
        else {
            is_book($mech);
        }
    }
}

sub is_article {
    my $mech = shift;
    $mech->content_lacks('{scrbook}');
    $mech->content_contains('{scrartcl}');
    $mech->content_contains('\let\chapter\section');
}

sub is_book {
    my $mech = shift;
    $mech->content_contains('{scrbook}');
    $mech->content_lacks('{scrartcl}');
    $mech->content_lacks('\let\chapter\section');
}
