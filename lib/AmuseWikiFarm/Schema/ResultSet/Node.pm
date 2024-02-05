package AmuseWikiFarm::Schema::ResultSet::Node;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use HTML::Entities qw/encode_entities/;
use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Utils::Amuse;

sub hri {
    return shift->search(undef, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' });
}

sub by_uri {
    my ($self, $uri) = @_;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.uri" => $uri });
}

sub find_by_uri {
    my ($self, $uri) = @_;
    return unless $uri;
    my $me = $self->current_source_alias;
    return $self->find({ "$me.uri" => $uri });
}

sub root_nodes {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.parent_node_id" => undef });
}

sub update_or_create_from_params {
    my ($self, $params, $opts) = @_;
    $opts ||= {};
    if (my $uri = AmuseWikiFarm::Utils::Amuse::muse_naming_algo($params->{uri})) {
        if ($opts->{create}) {
            return if $self->find({ uri => $uri });
        }
        my $node = $self->find_or_create({ uri => $uri });
        $node->discard_changes;
        $node->update_from_params($params);
        return $node;
    }
}

sub sorted {
    my $self = shift;
    my $me = $self->current_source_alias;
    $self->search(undef, { order_by => [map { $me . '.' . $_ } (qw/sorting_pos uri/) ] });
}

sub with_body {
    my ($self, $lang) = @_;
    my $me = $self->current_source_alias;
    $self->search({
                   'node_bodies.lang' => [ $lang || 'en', undef ],
                  },
                  {
                   prefetch => 'node_bodies',
                  });
}

sub all_nodes {
    my ($self, $lang) = @_;
    my $me = $self->current_source_alias;
    my @all = $self->with_body->hri;
    my @out;
    foreach my $node (@all) {
        my %node = (
                    value => $node->{node_id},
                    title => join('/', '', 'node', $node->{full_path}),
                    uri => $node->{uri},
                    label => encode_entities($node->{canonical_title} || $node->{uri}),
                   );
        push @out, \%node;
    }
    return \@out;
}

sub as_list_with_path {
    my ($self, $lang) = @_;
    my $source = $self->as_tree_source($lang);
    my @out;
    foreach my $node (values %$source) {
        push @out, {
                    value => $node->{node_id},
                    title => join(' / ', reverse(_get_path_label($source, $node->{node_id}))),
                    uri => $node->{uri},
                    label => $node->{canonical_title} || $node->{uri},
                    sorting_pos => $node->{sorting_pos},
                   };
    }
    @out = sort { $a->{title} cmp $b->{title} } @out;
    return \@out;
}

sub _get_path_label {
    my ($source, $id, $depth) = @_;
    $depth++;
    return unless $id;
    return if $depth > 10;
    my $node = $source->{$id};
    return unless $node;
    my @out = ($node->{title_html}, _get_path_label($source, $node->{parent_node_id}, $depth));
    return @out;
}


sub as_tree_source {
    my ($self, $lang) = @_;
    $lang ||= 'en';
    my $me = $self->current_source_alias;
    my @all = $self->search(undef,
                            {
                             prefetch => [
                                          'node_bodies',
                                          {
                                           node_categories => 'category',
                                           node_titles => 'title',
                                           node_aggregation_series => 'aggregation_series',
                                           node_aggregations => { aggregation => 'aggregation_series' },
                                          },
                                         ],
                            })->hri->all;
    Dlog_debug { "All nodes: $_ " } \@all;
    my %source;
    foreach my $n (@all) {
        $source{$n->{node_id}} = $n;
        # search the body by language
        my @bodies = @{ delete $n->{node_bodies} };
        my ($found) = ((grep { $_->{lang} eq $lang and $_->{title_html} } @bodies),
                       (grep { $_->{lang} eq 'en'  and $_->{title_html} } @bodies));
        if ($found) {
            $source{$n->{node_id}}{title_html} = $found->{title_html};
        }
        else {
            $source{$n->{node_id}}{title_html} = encode_entities($n->{canonical_title} || $n->{uri});
        }
    }
    Dlog_debug { "Flattened $_" } \%source;
    return \%source;
}

sub as_tree {
    my ($self, $lang, %opts) = @_;
    my $source = $self->as_tree_source($lang);
    my @out = map { _render_node($source, $_->{node_id}, 0, %opts) }
      sort { $a->{sorting_pos} <=> $b->{sorting_pos} or $a->{uri} cmp $b->{uri} }
      grep { !$_->{parent_node_id} } values %$source;
    return \@out;
}

sub _render_node {
    my ($source, $id, $depth, %opts) = @_;
    $depth ||= 0;
    log_debug { "Rendering $id $depth" };
    my $node = $source->{$id};
    my $root_indent = '  ' x $depth;
    my $indent = $root_indent . '  ';
    my $html = "\n" . $root_indent . "<div>\n";
    $html .= $indent . '<div>';
    my $class= $opts{class} || 'amw-label-node';
    $html .= sprintf('<div class="%s"><a href="%s">%s</a></div>',
                     $class,
                     '/node/' . $node->{full_path},
                     $node->{title_html});
    $html .= "</div>\n";
    my %icons = (
                 author => 'address-book-o',
                 topic => 'tag',
                 series => 'archive',
                 aggregations => 'book',
                 special => 'file-text-o',
                 text => 'file-text-o',
                );
    my @list;
    # here we need to sort.
    foreach my $series (@{$node->{node_aggregation_series} || []}) {
        if (my $s = $series->{aggregation_series}) {
            push @list, [
                         encode_entities($s->{aggregation_series_name}),
                         "/series/$s->{aggregation_series_uri}",
                         'archive',
                         $series->{sorting_pos},
                        ];
        }
    }
    foreach my $aggregation (@{$node->{node_aggregations} || []}) {
        if (my $agg = $aggregation->{aggregation}) {
            $agg->{aggregation_name} ||= join(' ', grep { /\w/ }
                                              ($agg->{aggregation_series}->{aggregation_series_name},
                                               $agg->{issue}));
            push @list, [ encode_entities($agg->{aggregation_name}),
                          "/aggregation/$agg->{aggregation_uri}",
                          'book',
                          $aggregation->{sorting_pos},
                        ];
        }
    }
    foreach my $category (@{$node->{node_categories}}) {
        if (my $cat = $category->{category}) {
            if ($cat->{active}) {
                push @list, [ $cat->{name},
                              "/category/$cat->{type}/$cat->{uri}",
                              $icons{$cat->{type}} || 'tag',
                              $category->{sorting_pos},
                            ];
            }
        }
    }
    foreach my $title (@{$node->{node_titles} || []}) {
        if (my $t = $title->{title}) {
            if ($t->{status} eq 'published') {
                my $full_uri = $t->{f_class} eq 'text'
                  ? "/library/$title->{uri}"
                  : "/special/$title->{uri}";
                push @list, [ $t->{title},
                              $full_uri,
                              $icons{$t->{f_class}},
                              $title->{sorting_pos},
                            ];
            }
        }
    }
    Dlog_debug { "My linked pages: $_" } \@list;
    if (@list) {
        $html .= join("",
                      $indent . "<ul>\n",
                      (map { $indent . sprintf(' <li><i class="text-primary fa fa-%s"></i> <a href="%s">%s</a></li>',
                                               $_->[2],
                                               $_->[1],
                                               $_->[0]) . "\n" }
                       sort { $a->[3] <=> $b->[3] }
                       @list),
                      $indent . "</ul>\n");
    }
    $depth++;
    if ($depth > 10) {
        log_error { "Recursion too deep! on $html" };
        return $html;
    }
    my @children_html;
    foreach my $child (sort { $a->{sorting_pos} <=> $b->{sorting_pos} or $a->{uri} cmp $b->{uri} }
                       grep { $_->{parent_node_id} and  $_->{parent_node_id} eq $id }
                       values %$source) {
        push @children_html, _render_node($source, $child->{node_id}, $depth, %opts);
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


1;
