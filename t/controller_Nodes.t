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

my $site = create_site($schema, '0nodes0');

{
    my $parent;
    foreach my $uri (qw/one two three four five six seven eight/) {
        my $node = $site->nodes->create({ uri => $uri });
        if ($parent) {
            $node->parent_node($parent);
            $node->update;
        }
        $parent = $node;
    }
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);


is $site->nodes->find({ uri => 'six' })->full_uri, '/nodes/one/two/three/four/five/six';
is $site->nodes->find({ uri => 'one' })->full_uri, '/nodes/one';

foreach my $node ($site->nodes) {
    my @ancestors = $node->ancestors;
    if ($node->uri eq 'one') {
        ok !scalar(@ancestors), "Root node";
        ok $node->is_root;
    }
    else {
        ok scalar(@ancestors), "Found ancestors";
    }
    diag $node->full_uri;
    $mech->get_ok($node->full_uri);
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
    my $node = $site->nodes->find_by_uri('one');
    diag $node->as_html;
}
{
    my $node = $site->nodes->find_by_uri('four');
    ok $node;
    my $title = $site->titles->text_by_uri('first');
    my $special = $site->titles->special_by_uri('second');
    $node->add_to_titles($title);
    $node->add_to_titles($special);
    $node->add_to_categories($site->categories->by_type_and_uri(qw/topic cat-third/));
    $node->add_to_categories($site->categories->by_type_and_uri(qw/author author-second/));
    is $node->titles->count, 2;
    is $node->categories->count, 2;
    diag Dumper($node->prepare_form_tokens);
    my $update = {
                  title_en => "Four",
                  body_en => "this\n\nwas a\n - list\n - list\n\n",
                 };
    $node->update_from_params($update);
    diag Dumper($node->prepare_form_tokens);
    my $params = get_params($node);
    is_deeply($params, $update, "Update is fine and idempotens");

    diag $node->as_html('en');

    $site->update({ multilanguage => 'en es de' });
    $node = $node->get_from_storage;
    my $multiparam = get_params($node);
    is scalar(keys %$multiparam), 6;
    ok exists($multiparam->{body_de});
    $multiparam->{body_de} = "> test me";
    $node->update_from_params($multiparam);
    is_deeply(get_params($node), $multiparam, "Multilang is fine as well");
    $mech->get('/node-editor/four/edit');
    ok $mech->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root' });
    $mech->get_ok('/node-editor/four/edit');
    $mech->get_ok('/node-editor/four/delete');
    $mech->get_ok('/node-editor');
}


sub get_params {
    my $node = shift;
    my %params;
    foreach my $token (@{$node->prepare_form_tokens}) {
        foreach my $k (qw/title body/) {
            $params{$token->{$k}->{param_name}} = $token->{$k}->{param_value};
        }
    }
    return \%params;
}
