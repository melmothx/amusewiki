#!perl
use utf8;
use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWikiFarm::Schema;
use Test::More tests => 99;
use Data::Dumper::Concise;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";

use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use HTML::Entities qw/encode_entities/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0nodes0');

{
    my $parent;
    foreach my $uri (qw/one two three four five six seven eight/) {
        my $node = $site->nodes->create({ uri => $uri });
        if ($parent) {
            $node->parent_node($parent);
            $node->update;
            $node->update_full_path;
        }
        $parent = $node;
    }
}

{
    diag "Fetching the breadcrumbs";
    my $node = $site->nodes->find({ uri => 'eight' });
    ok $node->breadcrumbs;
    diag Dumper($node->breadcrumbs);
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);


is $site->nodes->find({ uri => 'six' })->full_uri, '/node/one/two/three/four/five/six';
is $site->nodes->find({ uri => 'one' })->full_uri, '/node/one';

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
        $rev->edit(qq{#SORTtopics "x" <script>;\n#SORTauthors Author $id; author "<script>" kid\n}
                   . $rev->muse_body);
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
    diag Dumper($node->serialize);
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
    $mech->get('/node/four');
    ok(!$mech->form_id('node-edit-form'));
    $mech->get_ok('/login');
    ok $mech->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root' });
    {
        my $existing = $node->serialize;
        $node->update_from_params({ %$existing });
        is_deeply($node->serialize, $existing, "serialization is idempotens")
          or die Dumper($node->serialize, $existing);
    }
    $mech->get_ok('/node/four');
    diag $mech->uri;
    $mech->submit_form(with_fields => { title_en => 'Auuuu' },
                       button => 'update');
    is $node->discard_changes->name, 'Auuuu';
    $mech->content_contains('Auuuu');

    ok($mech->form_id('node-edit-form'));

    $mech->click('delete');
    ok (!$site->nodes->find_by_uri('four'), "Node deleted by posting") or die;
    is $mech->uri->path, '/node';

    $mech->get_ok('/user/site');
    ok !$site->home_page;
    $mech->submit_form(with_fields => { home_page => '/node/one/two' },
                       button => 'edit_site',
                      );
    is $site->discard_changes->home_page, '/node/one/two';
    $mech->get_ok('/');
    is $mech->uri->path, '/node/one/two';
}

{
    $site->update({ multilanguage => 'en it' });
    my %params = (
                  uri => 'pinco',
                  parent_node_uri => 'pallino',
                  attached_uris => "/library/first /special/third /library/first /special/third",
                  sorting_pos => 1,
                  title_en => "*pinco*",
                  body_en => "another *try*",
                  title_it => "*pinco it*",
                  body_it => "another *try* it",
                 );
    my $node = $site->nodes->update_or_create_from_params({ %params });
    is $node->name, "<em>pinco</em>";
    is $node->titles->count, 2, "Found titles";
    is $node->categories->count, 0, "Found 0 cats";
    $params{attached_uris} = "/library/first\n/special/third";
    my %copy = %params;
    # pallino doesn't exist yet, so will return undef
    $copy{parent_node_uri} = undef;
    is_deeply($node->serialize, \%copy);
    is $node->name('it'), "<em>pinco it</em>";

    $site->nodes->update_or_create_from_params({ uri => 'pallino' });
    # stuff it again
    $params{attached_uris} =~ s/\s+/\n/g;
    $node = $site->nodes->update_or_create_from_params({ %params });
    is_deeply($node->serialize, \%params);
    $copy{attached_uris} = undef;
    $copy{parent_node_uri} = 'pallino';
    $node = $site->nodes->update_or_create_from_params({ %copy });
    is_deeply($node->serialize, \%params);
    $copy{attached_uris} = '';
    $node = $site->nodes->update_or_create_from_params({ %copy });
    is $node->titles->count, 0;
    is $node->categories->count, 0;
    is $node->serialize->{attached_uris}, '';
}

{
    my %params = (
                  uri => 'pinco-x',
                  parent_node_uri => 'pallino',
                  attached_uris => "/category/author/author-script-kid /category/topic/x-script",
                  title_en => q{<script>"'pinco'"</script>"},
                  body_en => q{"another 'try'"},
                  title_it => q{"pinco <it>"},
                  body_it => q{"another" <try> 'it'},
                 );
    my $node = $site->nodes->update_or_create_from_params({ %params });
    diag Dumper({ $node->get_columns });
    diag Dumper($node->serialize);
    foreach my $lang (qw/en it/) {
        $mech->get_ok("/node?bare=1&__language=$lang");
        # diag $mech->content;
        $mech->content_lacks($params{"title_$lang"});
        my $expected = encode_entities($params{"title_$lang"});
        $expected =~ s/&#39;/&#x27;/g;
        $mech->content_contains($expected);

        $mech->content_contains('&quot;&lt;script&gt;&quot; kid</a>');
        $mech->content_lacks('"<script>" kid');
        $mech->content_contains('<a href="/category/topic/x-script">&quot;x&quot; &lt;script&gt;</a>');
        $mech->content_lacks(q{>"'pinco'"<});
        $mech->content_lacks(q{"x" <script>});
        $mech->content_contains(encode_entities(q{"x" <script>}));
        $mech->get_ok("/node?bare=1&__language=$lang");
        # $mech->page_links_ok; this will remove everything.
        $mech->get_ok($node->full_uri . "?bare=1&__language=$lang");
        diag $mech->uri;
        $mech->content_contains($expected);
        $mech->content_lacks($params{"title_$lang"}) or diag $mech->content;
        $mech->content_contains('>&quot;x&quot; &lt;script&gt;</a>') or diag $mech->content;
        $mech->content_lacks(q{"x" <script>}) or diag $mech->content;
        $mech->content_contains('&quot;&lt;script&gt;&quot; kid</a>');
        $mech->content_lacks('"<script>" kid');
    }
    $mech->get_ok($node->full_uri . '?bare=1');
    foreach my $param (qw/title_en title_it body_en body_it/) {
        $mech->content_lacks($params{$param});
        my $expected = encode_entities($params{$param});
        $expected =~ s/&#39;/&#x27;/g;
        $mech->content_contains($expected);
    }
    $mech->content_contains("/category/topic/x-script</textarea>");
    $mech->content_contains(">/category/author/author-script-kid\n");
}

my @node_ids = map { $_->node_id } $site->nodes;

foreach my $checked ([ single => $node_ids[0] ], [ all => \@node_ids ]) {
    my ($rev) = $site->create_new_text({
                                        title => "Assigned node " . $checked->[0],
                                        uri => "assigned-node-" . $checked->[0],
                                        node_id => $checked->[1],
                                       }, "text");
    $rev->commit_version;
    $rev->publish_text;
    if ($checked->[0] eq 'single') {
        is $rev->title->nodes->count, 1, "Single node attached";
    }
    else {
        ok $rev->title->nodes->count > 1, "Multiple nodes attached";
    }
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
