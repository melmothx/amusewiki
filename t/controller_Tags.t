#!perl
use utf8;
use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWikiFarm::Schema;
use Test::More tests => 30;
use Data::Dumper::Concise;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";

use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0tags0');

{
    my $parent;
    foreach my $uri (qw/one two three four five six seven eight/) {
        my $tag = $site->tags->create({ uri => $uri });
        if ($parent) {
            $tag->parent_tag($parent);
            $tag->update;
        }
        $parent = $tag;
    }
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);


is $site->tags->find({ uri => 'six' })->full_uri, '/tags/one/two/three/four/five/six';
is $site->tags->find({ uri => 'one' })->full_uri, '/tags/one';

foreach my $tag ($site->tags) {
    my @ancestors = $tag->ancestors;
    if ($tag->uri eq 'one') {
        ok !scalar(@ancestors), "Root node";
        ok $tag->is_root;
    }
    else {
        ok scalar(@ancestors), "Found ancestors";
    }
    diag $tag->full_uri;
    $mech->get_ok($tag->full_uri);
}

foreach my $id (qw/first second third/) {
    foreach my $type (qw/text special/) {
        my ($rev) = $site->create_new_text({
                                            title => "Title $type " . ucfirst($id),
                                            uri => $id,
                                            lang => 'en',
                                            textbody => '<p>hello there</p>',
                                            author => "Author $id",
                                            cat => "cat-$id",
                                           }, $type);
        $rev->commit_version;
        $rev->publish_text;
    }
}

# let's attach some texts

{
    my $tag = $site->tags->find_by_uri('one');
    diag $tag->as_html;
}
{
    my $tag = $site->tags->find_by_uri('four');
    ok $tag;
    my $title = $site->titles->text_by_uri('first');
    my $special = $site->titles->special_by_uri('second');
    $tag->add_to_titles($title);
    $tag->add_to_titles($special);
    $tag->add_to_categories($site->categories->by_type_and_uri(qw/topic cat-third/));
    $tag->add_to_categories($site->categories->by_type_and_uri(qw/author author-second/));
    is $tag->titles->count, 2;
    is $tag->categories->count, 2;
    diag Dumper($tag->prepare_form_tokens);
    my $update = {
                  title_en => "Four",
                  body_en => "this\n\nwas a\n - list\n - list\n\n",
                 };
    $tag->update_from_params($update);
    diag Dumper($tag->prepare_form_tokens);
    my $params = get_params($tag);
    is_deeply($params, $update, "Update is fine and idempotens");

    diag $tag->as_html('en');

    $site->update({ multilanguage => 'en es de' });
    $tag = $tag->get_from_storage;
    my $multiparam = get_params($tag);
    is scalar(keys %$multiparam), 6;
    ok exists($multiparam->{body_de});
    $multiparam->{body_de} = "> test me";
    $tag->update_from_params($multiparam);
    is_deeply(get_params($tag), $multiparam, "Multilang is fine as well");

    $mech->get('/tag-editor/four/update');
    ok $mech->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root' });
    diag $mech->content;
    $mech->get_ok('/tag-editor/four/update');
    $mech->get_ok('/tag-editor/four/delete');
    $mech->get_ok('/tag-editor');

}

sub get_params {
    my $tag = shift;
    my %params;
    foreach my $token (@{$tag->prepare_form_tokens}) {
        foreach my $k (qw/title body/) {
            $params{$token->{$k}->{param_name}} = $token->{$k}->{param_value};
        }
    }
    return \%params;
}
