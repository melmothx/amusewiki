#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 203;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;
use AmuseWikiFarm::Utils::Amuse qw/from_json/;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(utf-8)";

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0cc0';

my $site = create_site($schema, $site_id);
is $site->site_category_types->count, 2;
# check if it dies;
$site->init_category_types;

foreach my $ctype ({
                    category_type => 'publisherx',
                    active => 1,
                    priority => 2,
                    name_singular => 'Publisherx',
                    name_plural => 'Publishers',
                    xapian_custom_slot => 1,
                   },
                   {
                    category_type => 'location',
                    active => 1,
                    priority => 3,
                    name_singular => 'Location',
                    name_plural => 'Locations',
                    xapian_custom_slot => 2,
                   },
                   {
                    category_type => 'season',
                    active => 1,
                    priority => 4,
                    name_singular => 'Season',
                    name_plural => 'Seasons',
                    xapian_custom_slot => 3,
                   }) {
    $site->site_category_types->find_or_create($ctype);
}
$site->discard_changes;
is $site->site_category_types->count, 5;

foreach my $i (1..3) {
    my ($rev) = $site->create_new_text({
                                        title => "$i Hello $i",
                                        textbody => 'Hey',
                                        publisherx => "Pinco $i, Pallino $i",
                                        location => "Washington, DC; Zagreb, Croatia; 東京, Japan;",
                                        season => q{summer $i my'"&"'<stuff>"},
                                       }, "text");
    diag $rev->muse_body;
    like $rev->muse_body, qr{#publisherx Pinco};
    like $rev->muse_body, qr{#location Wash};
    like $rev->muse_body, qr{#season summer};
    $rev->commit_version;
    $rev->publish_text;
}

ok $site->categories->count;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
$mech->get_ok('/');
$mech->get_ok('/login');
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
$mech->get_ok('/action/text/new');
$mech->content_contains('name="location"');
$mech->content_contains('name="publisherx"');
$mech->content_contains('name="season"');
foreach my $c ($site->categories) {
    diag join(' ', $c->type, $c->uri, $c->name, $c->titles->count);
    $mech->get_ok($c->full_uri);
    $mech->get($c->full_uri . '?bare=1');
    foreach my $title ($c->titles) {
        my $url = $title->full_uri;
        $mech->content_contains($title->full_uri, "Found $url in " . $c->full_uri);
    }
}

foreach my $ct (qw/location publisherx season/) {
    $mech->get_ok("/api/autocompletion/$ct");
    my $data = from_json($mech->response->content);
    ok (scalar(@$data), Dumper($data));
}

$site->site_category_types->update({ active => 0 });

foreach my $c ($site->categories) {
    diag join(' ', $c->type, $c->uri, $c->name, $c->titles->count);
    $mech->get($c->full_uri);
    is $mech->status, 404;
}

$site->site_category_types->update({ active => 1 });

foreach my $c ($site->categories) {
    diag join(' ', $c->type, $c->uri, $c->name, $c->titles->count);
    $mech->get_ok($c->full_uri);
}

foreach my $t ($site->titles) {
    $mech->get_ok($t->full_uri);
    foreach my $c ($t->categories) {
        $mech->content_contains($c->full_uri);
    }
}

ok $site->edit_category_types_from_params({
                                           create => 'pippo',
                                           publisherx_active => 0,
                                           publisherx_priority => 4,
                                           publisherx_name_singular => 'P',
                                           publisherx_name_plural => 'PP',
                                           publisherx_assign_xapian_custom_slot => 1,
                                          });
{
    my $cc = $site->site_category_types->find({ category_type => 'pippo' });
    ok $cc;
    ok $cc->active;
    is $cc->name_plural, 'Pippos';
    is $cc->name_singular, 'Pippo';

}
{
    my $cc = $site->site_category_types->find({ category_type => 'publisherx' });
    ok $cc;
    ok !$cc->active;
    is $cc->name_plural, 'PP';
    is $cc->name_singular, 'P';
}

{
    $site = $site->get_from_storage;
    diag Dumper($site->custom_category_types);
}

foreach my $cat ($site->categories) {
    diag $cat->name . ' ' . $cat->full_uri;
}

foreach my $text ($site->titles) {
    foreach my $header ($text->muse_headers) {
        diag $header->muse_header;
        ok $header->as_html;
        diag $header->as_html;
    }
}
{
    my $rev = $site->titles->first->new_revision;
    diag Dumper($rev->document_html_headers);
    diag Dumper($rev->document_preview_fields);
}

{
    my @indexed = (qw/pippo season/);
    my @not_indexed = (qw/publisherx location/);

    $site->site_category_types->search({ category_type => \@not_indexed })
      ->update({ generate_index => 0, active => 1 });
    $site->site_category_types->search({ category_type => \@indexed })
      ->update({ generate_index => 1, active => 1 });
    $site = $site->get_from_storage;
    diag Dumper($site->custom_category_types);
    $mech->get_ok('/action/text/new');
    my $form = $mech->content;
    # check the form
    my %submit = (title => 'test-custom-fields', uri => 'test-custom-fields', textbody => "<p>TEst</p>");
    foreach my $f (@indexed, @not_indexed) {
        like $form, qr{name="\Q$f\E"}, "Form contains $f field";
        $mech->get_ok("/api/autocompletion/$f", "autocompletion for $f ok");
        diag $mech->content;
        $submit{$f} = "<1$f>; <2$f>";
    }
    $mech->get_ok('/action/text/new');
    $mech->submit_form(with_fields => \%submit, button => 'go');
    my $html = $mech->content;
    if ($html =~ m{<textarea.*?>(.*?)</textarea>}s) {
        my $muse_body = $1;
        diag "Body is $muse_body";
        foreach my $f (@indexed, @not_indexed) {
            like $muse_body, qr{\#\Q$f\E \&lt\;1\Q$f\E\&gt\;\; \&lt\;2\Q$f\E\&gt\;\n}, "$f found in muse body";
        }
    }
    else {
        die "textarea not found";
    }
    $mech->uri =~ m{/(\d+)$};
    my $rev = $schema->resultset('Revision')->find($1);
    diag Dumper($rev->document_preview_fields);
    my $preview = $mech->uri . '/preview?bare=1';
    $mech->get_ok($preview);
    my $preview_html = $mech->content;
    foreach my $f (@indexed) {
        like $preview_html, qr{<a class="cf-preview-target-url".*?>\&lt\;1\Q$f\E\&gt\;</a>};
    }
    foreach my $f (@not_indexed) {
        like $preview_html, qr{<span class="cf-preview-target-html">\&lt\;1\Q$f\E\&gt\;\; \&lt\;\Q2$f\E\&gt\;</span>};
    }
    $rev->commit_version;
    my $uri = $rev->publish_text;
    $mech->get_ok($uri . '?bare=1');
    my $final_html = $mech->content;
    diag $final_html;
    foreach my $f (@indexed) {
        like $final_html, qr{<a .*?class="text-\Q$f\Es-item">\&lt\;1\Q$f\E\&gt\;</a>};
        like $final_html, qr{<a .*?class="text-\Q$f\Es-item">\&lt\;2\Q$f\E\&gt\;</a>};
        $mech->get_ok("/category/$f");
    }
    foreach my $f (@not_indexed) {
        $mech->get("/category/$f");
        is $mech->status, 404;
        like $final_html, qr{<span class="text-cf-\Q$f\Es-html">\&lt\;1\Q$f\E\&gt\;\; \&lt\;\Q2$f\E\&gt\;</span>};
    }
    # now flip the indexed flag and check if the texts flip
    $site->site_category_types->search({ category_type => \@not_indexed })
      ->update({ generate_index => 1, active => 1 });
    $mech->get_ok($uri . '?bare=1');
    my $updated_final_html = $mech->content;
    foreach my $f (@indexed, @not_indexed) {
        like $updated_final_html, qr{<a .*?class="text-\Q$f\Es-item">\&lt\;1\Q$f\E\&gt\;</a>};
        like $updated_final_html, qr{<a .*?class="text-\Q$f\Es-item">\&lt\;2\Q$f\E\&gt\;</a>};
    }
    $mech->get_ok($preview);
    my $updated_preview_html = $mech->content;
    foreach my $f (@indexed, @not_indexed) {
        like $updated_preview_html, qr{<a class="cf-preview-target-url".*?>\&lt\;1\Q$f\E\&gt\;</a>};
        $mech->get_ok("/category/$f");
    }
    $site->site_category_types->search({ category_type => [ @indexed, @not_indexed ] })
      ->update({ in_colophon => 1 });

    $site = $site->get_from_storage;
    my %check_colophon = map { $_ => "$_, $_" } (@indexed, @not_indexed);
    like $site->_autocreate_colophon(\%check_colophon), qr{\*\*Locations\*\*:.*location};
    %check_colophon = map { $_ => "$_" } (@indexed, @not_indexed);
    like $site->_autocreate_colophon(\%check_colophon), qr{\*\*Location\*\*:.*location};

    my $res = $site->xapian->faceted_search(site => $site,
                                            lh => $site->localizer,
                                            locale => 'en',
                                            query => '',
                                           );
    diag Dumper($res->facet_tokens);
    my ($season_facets) = grep { $_->{name} eq 'filter_custom3' } @{ $res->facet_tokens };
    ok scalar(@{$season_facets->{facets}}), "Found facets for season";
}
{
    $mech->get_ok('/action/text/new');
    my %submit = (
                  title => 'MY TITLE',
                  sku => 'MY SKU',
                  rights => 'MY COPYRIGHT',
                  seriesname => 'MY SERIES NAME',
                  seriesnumber => 'MY SERIES NUMBER',
                  isbn => 'MY ISBN',
                  publisher => 'MY PUBLISHER',
                 );
    $mech->submit_form(with_fields => \%submit, button => 'go');
    my $html = $mech->content;
    if ($html =~ m{<textarea.*?>(.*?)</textarea>}s) {
        my $muse_body = $1;
        diag "Body is $muse_body";
        foreach my $f (keys %submit) {
            like $muse_body, qr{\#\Q$f\E \Q$submit{$f}\E\n}, "$f found in muse body";
        }
    }
    else {
        die "textarea not found";
    }
    $mech->uri =~ m{/(\d+)$};
    my $rev = $schema->resultset('Revision')->find($1);
    my $preview = $mech->uri . '/preview?bare=1';
    foreach my $check (values %submit) {
        $mech->content_contains($check);
    }
    $rev->commit_version;
    my $uri = $rev->publish_text;
    $mech->get_ok($uri . '?bare=1');
    foreach my $check (values %submit) {
        $mech->content_contains($check);
    }
    $mech->get_ok($uri . '.html');
    delete $submit{sku}; # special case, doesn't enter the formats
    foreach my $check (values %submit) {
        $mech->content_contains($check);
    }
}

{
    my $cc = $site->site_category_types->create({
                                                 category_type => 'dummy',
                                                 active => 1,
                                                 priority => 9,
                                                 name_singular => 'Dummy',
                                                 name_plural => 'Dummy',
                                                 description => "Dummy entry",
                                                 generate_index => 0,
                                                });
    $cc->discard_changes;
    is $cc->generate_index, 0;
    is $cc->xapian_custom_slot, undef;
    ok $cc->assign_xapian_custom_slot, "Assigned xapian custom slot";
    is $cc->xapian_custom_slot, 4;
    is $cc->generate_index, 1, "Generate index has been turned on";
}
