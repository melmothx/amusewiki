use utf8;
package AmuseWikiFarm::Schema::Result::Node;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Node - Nestable nodes

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<node>

=cut

__PACKAGE__->table("node");

=head1 ACCESSORS

=head2 node_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 uri

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 parent_node_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "node_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "uri",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "parent_node_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</node_id>

=back

=cut

__PACKAGE__->set_primary_key("node_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<site_id_uri_unique>

=over 4

=item * L</site_id>

=item * L</uri>

=back

=cut

__PACKAGE__->add_unique_constraint("site_id_uri_unique", ["site_id", "uri"]);

=head1 RELATIONS

=head2 node_bodies

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::NodeBody>

=cut

__PACKAGE__->has_many(
  "node_bodies",
  "AmuseWikiFarm::Schema::Result::NodeBody",
  { "foreign.node_id" => "self.node_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 node_categories

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::NodeCategory>

=cut

__PACKAGE__->has_many(
  "node_categories",
  "AmuseWikiFarm::Schema::Result::NodeCategory",
  { "foreign.node_id" => "self.node_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 node_titles

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::NodeTitle>

=cut

__PACKAGE__->has_many(
  "node_titles",
  "AmuseWikiFarm::Schema::Result::NodeTitle",
  { "foreign.node_id" => "self.node_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodes

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::Node>

=cut

__PACKAGE__->has_many(
  "nodes",
  "AmuseWikiFarm::Schema::Result::Node",
  { "foreign.parent_node_id" => "self.node_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 parent_node

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Node>

=cut

__PACKAGE__->belongs_to(
  "parent_node",
  "AmuseWikiFarm::Schema::Result::Node",
  { node_id => "parent_node_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
);

=head2 site

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Site>

=cut

__PACKAGE__->belongs_to(
  "site",
  "AmuseWikiFarm::Schema::Result::Site",
  { id => "site_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 categories

Type: many_to_many

Composing rels: L</node_categories> -> category

=cut

__PACKAGE__->many_to_many("categories", "node_categories", "category");

=head2 titles

Type: many_to_many

Composing rels: L</node_titles> -> title

=cut

__PACKAGE__->many_to_many("titles", "node_titles", "title");


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2019-04-05 08:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wvwnVE7iZWdNMtXhrabmuA

use AmuseWikiFarm::Log::Contextual;
use Text::Amuse::Functions qw/muse_to_object
                              muse_format_line
                             /;
use HTML::Entities qw/encode_entities/;

sub children {
    return shift->nodes;
}

sub parent {
    return shift->parent_node;
}

sub is_root {
    return !shift->parent_node_id;
}

sub ancestors {
    my $self = shift;
    my @ancestors;
    my $rec = $self;
    my $max = 0;
    # max 10 as deep. Seems even too much
    while (++$max < 10 and $rec = $rec->parent) {
        push @ancestors, $rec;
    }
    return @ancestors;
}

sub full_uri {
    my $self = shift;
    my @path = ($self->uri, (map { $_->uri } $self->ancestors));
    return join('/', '', nodes => reverse(@path));
}

sub update_from_params {
    my ($self, $params) = @_;
    Dlog_debug { "Updating " . $self->full_uri . " with $_" } $params;
    my $site = $self->site;
    my @locales = $site->supported_locales;
    my $guard = $self->result_source->schema->txn_scope_guard;
    $self->node_bodies->search({ lang => \@locales })->delete;
    foreach my $lang (@locales) {
        my %body = (
                    title_muse => $params->{'title_' . $lang} || '',
                    body_muse => $params->{'body_' . $lang} || '',
                    lang => $lang,
                   );
        $body{title_html} = muse_format_line(html => $body{title_muse}, $lang);
        $body{body_html} = muse_to_object($body{body_muse})->as_html;
        $self->add_to_node_bodies(\%body);
    }
    my $parent;
    if ($params->{parent_node_id} and $site->nodes->find($params->{parent_node_id})) {
        $parent = $params->{parent_node_id};
    }
    $self->update({ parent_node_id => $parent });
    $guard->commit;
}

# we do all the languages in a single page, to simplify
sub prepare_form_tokens {
    my $self = shift;
    my @out;
    foreach my $lang ($self->site->supported_locales) {
        my $desc = $self->node_bodies->find({ lang => $lang });
        push @out, {
                    lang => $lang,
                    title => {
                              param_name => 'title_' . $lang,
                              param_value => $desc ? $desc->title_muse : '',
                             },
                    body => {
                             param_name => 'body_' . $lang,
                             param_value => $desc ? $desc->body_muse : '',
                            },
                    title_html => $desc ? $desc->title_html : '',
                    body_html =>  $desc ? $desc->body_html  : '',
                   };
    }
    return \@out;
}

sub linked_pages_as_html {
    my ($self, %options) = @_;
    my $indent = $options{indent} || '';
    my @list;
    my $titles = $self->titles->published_all;
    while (my $title = $titles->next) {
        push @list, [ $title->author_title, $title->full_uri ];
    }
    my $cats = $self->categories->active_only->sorted;
    while (my $cat = $cats->next) {
        push @list, [ $cat->name, $cat->full_uri ];
    }
    if (@list) {
        return join("",
                    $indent . "<ul>\n",
                    (map { $indent . sprintf(' <li><a href="%s">%s</a></li>', $_->[1], $_->[0]) . "\n" } @list),
                    $indent . "</ul>\n");
    }
    else {
        return '';
    }
}

sub as_html {
    my ($self, $lang, $depth) = @_;
    $depth ||= 0;
    $lang ||= 'en';
    # this is not to be pretty.
    # First, retrieve the body.
    log_debug { "Descending into " . $self->uri };
    my $root_indent = '  ' x $depth;
    my $indent = $root_indent . '  ';
    my $html = "\n" . $root_indent . "<div>\n";
    my $desc = $self->node_bodies->not_empty->find_by_lang($lang) ||
      $self->node_bodies->not_empty->find_by_lang('en');
    my $title = encode_entities($self->uri);
    if ($desc && $desc->title_html) {
        $title = $desc->title_html;
    }
    $html .= $indent . sprintf('<div><strong>%s</strong></div>', $title) . "\n";
    $html .= $self->linked_pages_as_html(indent => $indent);
    $depth++;
    if ($depth > 10) {
        log_error { "Recursion too deep! on $html" };
        return $html;
    }
    my $children = $self->children;
    my @children_html;
    while (my $child = $children->next) {
        push @children_html, $child->as_html($lang, $depth);
    }
    if (@children_html) {
        $html .= join("",
                      $indent . "<ul>\n",
                      (map { $indent . '<li>' . $_ . "\n" . $indent . "</li>\n" } @children_html),
                      $indent . "</ul>\n");
    }
    $html .= $root_indent . "</div>";
    return $html;
}

__PACKAGE__->meta->make_immutable;
1;
