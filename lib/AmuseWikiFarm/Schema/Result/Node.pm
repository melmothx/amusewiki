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

=head2 canonical_title

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 last_updated_epoch

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 last_updated_dt

  data_type: 'datetime'
  is_nullable: 1

=head2 sorting_pos

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 full_path

  data_type: 'text'
  is_nullable: 1

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
  "canonical_title",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "last_updated_epoch",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "last_updated_dt",
  { data_type => "datetime", is_nullable => 1 },
  "sorting_pos",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "full_path",
  { data_type => "text", is_nullable => 1 },
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

=head2 node_aggregation_series

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::NodeAggregationSeries>

=cut

__PACKAGE__->has_many(
  "node_aggregation_series",
  "AmuseWikiFarm::Schema::Result::NodeAggregationSeries",
  { "foreign.node_id" => "self.node_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 node_aggregations

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::NodeAggregation>

=cut

__PACKAGE__->has_many(
  "node_aggregations",
  "AmuseWikiFarm::Schema::Result::NodeAggregation",
  { "foreign.node_id" => "self.node_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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

=head2 aggregation_series

Type: many_to_many

Composing rels: L</node_aggregation_series> -> aggregation_series

=cut

__PACKAGE__->many_to_many(
  "aggregation_series",
  "node_aggregation_series",
  "aggregation_series",
);

=head2 aggregations

Type: many_to_many

Composing rels: L</node_aggregations> -> aggregation

=cut

__PACKAGE__->many_to_many("aggregations", "node_aggregations", "aggregation");

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


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2024-01-20 15:08:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:e2qKuKUuWxgCTWN71140JA

use AmuseWikiFarm::Log::Contextual;
use Text::Amuse::Functions qw/muse_to_object
                              muse_format_line
                             /;
use HTML::Entities qw/encode_entities/;
use AmuseWikiFarm::Utils::Amuse ();
use DateTime;

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
    return join('/', '', node => $self->full_path || $self->update_full_path);
}

sub update_from_params {
    my ($self, $params) = @_;
    $params ||= {};
    Dlog_debug { "Updating " . $self->full_uri . " with $_" } $params;
    my $site = $self->site;
    my @locales = $site->supported_locales;
    my $guard = $self->result_source->schema->txn_scope_guard;
    my %nodes;
    foreach my $n ($self, $self->ancestors) {
        $nodes{$n->node_id} = $site->oai_pmh_sets->find_or_create({
                                                                   set_spec => $n->oai_pmh_set_spec,
                                                                   set_name => $n->canonical_title,
                                                                  },
                                                                  { key => 'set_spec_site_id_unique' });
    }
    # collect existing records. We will need to bump them.
    my @oai_pmh_record_ids = map { $_->oai_pmh_record_id } map { $_->oai_pmh_record_sets->all } values %nodes;

  LANG:
    foreach my $lang (@locales) {
        my $title = $params->{'title_' . $lang};
        my $body = $params->{'body_' . $lang};
        # be sure it's coming from the form
        next LANG unless defined($title) && defined($body);
        my %body = (
                    title_muse => $params->{'title_' . $lang} || '',
                    body_muse => $params->{'body_' . $lang} || '',
                    lang => $lang,
                   );
        $body{title_html} = muse_format_line(html => $body{title_muse}, $lang);
        $body{body_html} = muse_to_object($body{body_muse})->as_html;
        $self->node_bodies->update_or_create(\%body);
    }
    if (defined $params->{parent_node_uri}) {
        if (my $parent = $site->nodes->find_by_uri($params->{parent_node_uri})) {
            $self->parent_node($parent);
        }
        else {
            $self->parent_node(undef);
        }
    }
    if (defined $params->{sorting_pos} and $params->{sorting_pos} =~ m/\A[1-9][0-9]*\z/) {
        log_debug { "Setting sorting pos to $params->{sorting_pos}" };
        $self->sorting_pos($params->{sorting_pos});
    }
    $self->canonical_title($params->{canonical_title} || ucfirst($self->uri));
    my $now = DateTime->now(time_zone => 'UTC');
    # informative only
    $self->last_updated_dt($now);
    $self->last_updated_epoch($now->epoch);
    $self->update;
    $self->update_full_path;
    if (defined $params->{attached_uris}) {
        my @list = ref($params->{attached_uris})
          ? (@{$params->{attached_uris}})
          : (split(/\s+/, $params->{attached_uris}));
        my (@titles, @cats, @aggs, @series);

        # all of them have a shared api, so we can loop
        my @objects = (
                       {
                        list => [],
                        method => 'set_titles',
                        rs => scalar($site->titles),
                       },
                       {
                        list => [],
                        method => 'set_categories',
                        rs => scalar($site->categories),
                       },
                       {
                        list => [],
                        method => 'set_aggregations',
                        rs => scalar($site->aggregations),
                       },
                       {
                        list => [],
                        method => 'set_aggregation_series',
                        rs => scalar($site->aggregation_series),
                       },
                      );
        my %done;
      STRING:
        foreach my $str (@list) {
          OBJECT:
            foreach my $obj (@objects) {
                if (my $found = $obj->{rs}->by_full_uri($str)) {
                    my $u = $found->full_uri;
                    $done{$u}++;
                    push @{$obj->{list}}, $found if $done{$u} == 1;
                    next OBJECT;
                }
            }
            Dlog_info { "Ignored $str while updating from params $_"} $params;
        }

        Dlog_info { "Done $_" } \%done;
        foreach my $obj (@objects) {
            my $method = $obj->{method};
            $self->$method($obj->{list});
        }
    }
    # we need to change the linkage between the record and the set and
    # bumps the new ones.
    my $tree = $site->node_title_tree;
    my $self_node_id = $self->node_id;
    Dlog_debug { "Initial list of PMH records is $_"  } \@oai_pmh_record_ids;
    foreach my $tree_spec (grep { $nodes{$_->{node_id}} } @{ $tree->{nodes} || []}) {
        Dlog_debug { "Updating $_" } $tree_spec;
        my @new_oai_pmh_records = $site->oai_pmh_records->by_title_id($tree_spec->{title_ids})->landing_pages_only->all;
        # this should clear the existing one and relink
        $nodes{$tree_spec->{node_id}}->set_oai_pmh_records(\@new_oai_pmh_records);
        push @oai_pmh_record_ids, map { $_->oai_pmh_record_id } @new_oai_pmh_records;
    }
    Dlog_debug { "Final list of PMH records is $_"  } \@oai_pmh_record_ids;
    $site->oai_pmh_records->by_id(\@oai_pmh_record_ids)->bump_datestamp if @oai_pmh_record_ids;
    $guard->commit;
}

# we do all the languages in a single page, to simplify
sub prepare_form_tokens {
    my $self = shift;
    my @out;
    my $lang_labels = AmuseWikiFarm::Utils::Amuse::known_langs();
    foreach my $lang ($self->site->supported_locales) {
        my $desc = $self->node_bodies->find({ lang => $lang });
        push @out, {
                    lang => $lang,
                    lang_label => $lang_labels->{$lang},
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

sub serialize {
    my $self = shift;
    my $parent = $self->parent;
    my %out = (
               uri => $self->uri,
               canonical_title => $self->canonical_title,
               parent_node_uri => $parent ? $parent->uri : undef,
               sorting_pos => $self->sorting_pos,
              );
    foreach my $desc ($self->node_bodies->all) {
        my $lang = $desc->lang;
        $out{'title_' . $lang} = $desc->title_muse;
        $out{'body_'  . $lang} = $desc->body_muse;
    }
    my @attached = map { $_->full_uri } (
                                         $self->aggregation_series->sorted->all,
                                         $self->aggregations->sorted->all,
                                         $self->categories->sorted->all,
                                         $self->titles->sorted_by_title->all,
                                        );
    $out{attached_uris} = join("\n", @attached);
    return \%out;
}

sub linked_pages {
    my $self = shift;
    my @out;
    my %icons = (
                 author => 'address-book-o',
                 topic => 'tag',
                 series => 'archive',
                 aggregations => 'book',
                 special => 'file-text-o',
                 text => 'file-text-o',
                );
    push @out, map { +{ label => encode_entities($_->aggregation_series_name),
                        type => "series",
                        uri => $_->full_uri } } $self->aggregation_series->sorted;
    push @out, map { +{ label => encode_entities($_->final_name),
                        type => "aggregation",
                        uri => $_->full_uri } } $self->aggregations->sorted;
    # these are already escaped
    push @out, map { +{ label => $_->name,
                        type => $_->type,
                        uri => $_->full_uri } } $self->categories->active_only->sorted;
    push @out, map { +{ label => $_->author_title,
                        type => $_->f_class,
                        uri => $_->full_uri } } $self->titles->sorted->published_all;
    Dlog_debug { "linked pages: $_" } \@out;
    foreach my $i (@out) {
        $i->{icon} = $icons{$i->{type}} || 'tags';
    }
    return @out;
}

sub children_pages {
    my ($self, %options) = @_;
    my $locale = $options{locale} || 'en';
    my @out;
    foreach my $child ($self->children->sorted) {
        push @out, {
                    label => $child->name($locale),
                    uri => $child->full_uri,
                   };
    }
    Dlog_debug { "children nodes are $_" } \@out;
    return @out;
}

sub linked_pages_as_html {
    my ($self, %options) = @_;
    my $indent = $options{indent} || '';
    my @list;
    my $titles = $self->titles->sorted_by_title;
    while (my $title = $titles->next) {
        push @list, [ $title->author_title, $title->full_uri ];
    }
    my $cats = $self->categories->sorted;
    while (my $cat = $cats->next) {
        push @list, [ $cat->name, $cat->full_uri ];
    }
    if (@list) {
        return join("",
                    $indent . "<ul>\n",
                    (map { $indent . sprintf(' <li><a href="%s">%s</a></li>', $_->[1], $_->[0]) . "\n" }
                     sort { $a->[1] cmp $b->[1] }
                     @list),
                    $indent . "</ul>\n");
    }
    else {
        return '';
    }
}

sub as_html {
    my ($self, $lang, $depth, %options) = @_;
    $depth ||= 0;
    $lang ||= 'en';
    # this is not to be pretty.
    # First, retrieve the body.
    #Dlog_debug { "Descending into $lang $depth " . $self->uri . " $_" } \%options;
    my $root_indent = '  ' x $depth;
    my $indent = $root_indent . '  ';
    my $html = "\n" . $root_indent . "<div>\n";
    $html .= $indent . '<div>';
    $html .= sprintf('<strong><a href="%s">%s</a></strong>',
                     $self->full_uri,
                     $self->name($lang));
    $html .= "</div>\n";
    $html .= $self->linked_pages_as_html(indent => $indent);
    $depth++;
    if ($depth > 10) {
        log_error { "Recursion too deep! on $html" };
        return $html;
    }
    my $children = $self->children->sorted;
    my @children_html;
    while (my $child = $children->next) {
        push @children_html, $child->as_html($lang, $depth, %options);
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

sub muse_name {
    my ($self, $lang) = @_;
    my $desc = $self->description($lang);
    my $name = $desc ? $desc->title_muse : $self->canonical_title || $self->uri;
    return $name;
}

sub name {
    my ($self, $lang) = @_;
    if (my $desc = $self->description($lang)) {
        return $desc->title_html;
    }
    else {
        # fallback
        return encode_entities($self->canonical_title || $self->uri);
    }
}

sub description {
    my ($self, $lang) = @_;
    $lang ||= 'en';
    my $desc = $self->node_bodies->not_empty->find_by_lang($lang) ||
      $self->node_bodies->not_empty->find_by_lang('en');
    return $desc;
}

sub breadcrumbs {
    my ($self, $lang) = @_;
    my $site = $self->site;
    my $lh = $site->localizer($lang);
    my @breadcrumbs = ({
                        uri => $self->full_uri,
                        label => $self->name($lang),
                       });
    my @full = my @path = $self->ancestors;
    foreach my $ancestor (@path) {
        push @breadcrumbs, {
                            uri => join('/', '', node => map { $_->uri} reverse @full),
                            label => $ancestor->name($lang),
                           };
        shift @full;
    }
    push @breadcrumbs, {
                        uri => "/node",
                        label => $lh->loc_html('Collections'),
                       };
    push @breadcrumbs, {
                        uri => "/",
                        label => $lh->loc_html('Home'),
                       };
    return [ reverse @breadcrumbs ];
}

sub title_ids {
    my $self = shift;
    my %hri = (result_class => 'DBIx::Class::ResultClass::HashRefInflator');
    my @ids = map { $_->{id} } $self->titles->search(undef,
                                                     {
                                                      columns => [qw/id/],
                                                      %hri,
                                                     });
    # Dlog_debug { "Direct ids for " . $self->uri . " are $_" } \@ids;
    my @catids = map { $_->{title_id} } $self->categories->search_related('title_categories')->search(undef,
                                                                                                      {
                                                                                                       columns => [qw/title_id/],
                                                                                                       %hri,
                                                                                                      });
    # Dlog_debug { "Ids via category for " . $self->uri . " are $_" } \@catids;
    return [ @ids, @catids];
}


sub update_full_path {
    my $self = shift;
    $self->discard_changes;
    my $full = join('/', reverse ($self->uri, (map { $_->uri } $self->ancestors)));
    $self->update({ full_path =>  $full });
    log_debug { "Updated full_path to $full" };
    return $full;
}

sub oai_pmh_set_spec {
    my $self = shift;
    return "collection:" . $self->uri;
}

after insert => sub {
    my $self = shift;
    $self->update_full_path;
    $self->update_from_params;
};

before delete => sub {
    my $self = shift;
    if (my $oaipmh_set = $self->site->oai_pmh_sets->find({ set_spec => $self->oai_pmh_set_spec })) {
        $self->update_from_params;
        log_debug { "Deleting the OAI_PMH set" };
        $oaipmh_set->delete;
    }
};

__PACKAGE__->meta->make_immutable;
1;
