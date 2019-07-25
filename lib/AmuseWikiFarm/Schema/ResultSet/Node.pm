package AmuseWikiFarm::Schema::ResultSet::Node;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use HTML::Entities qw/encode_entities/;
use AmuseWikiFarm::Log::Contextual;

sub hri {
    return shift->search(undef, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' });
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
    my ($self, $params) = @_;
    if (my $uri = $params->{uri}) {
        if ($uri =~ m/([a-z0-9][a-z0-9-]*[a-z0-9])/) {
            $uri = $1;
            $uri =~ s/--+/-/g;
            my $node = $self->find_or_create({ uri => $uri });
            $node->discard_changes;
            $node->update_from_params($params);
            return $node;
        }
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
                    label => encode_entities($node->{uri}),
                   );
        if (@{$node->{node_bodies}}) {
            if (my $label = $node->{node_bodies}->[0]->{title_html}) {
                $node{label} = $label;
            }
        }
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
                    label => $node->{uri},
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
            $source{$n->{node_id}}{title_html} = encode_entities($n->{uri});
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

    my @list;
    if (my @titles = @{$node->{node_titles}}) {
        foreach my $title (sort { $a->{sorting_pos} <=> $b->{sorting_pos} }
                           grep { $_->{status} eq 'published' }
                           map { $_->{title} }
                           @titles) {
            my $full_uri = $title->{f_class} eq 'text'
              ? "/library/$title->{uri}"
              : "/special/$title->{uri}";
            push @list, [ $title->{title}, $full_uri ];
        }
    }
    if (my @categories = @{$node->{node_categories}}) {
        foreach my $cat (sort { $a->{sorting_pos} <=> $b->{sorting_pos} }
                         grep { $_->{active} }
                         map { $_->{category} }
                         @categories) {
            push @list, [ $cat->{name}, "/category/$cat->{type}/$cat->{uri}"] ;
        }
    }
    if (@list) {
        $html .= join("",
                      $indent . "<ul>\n",
                      (map { $indent . sprintf(' <li><a href="%s">%s</a></li>', $_->[1], $_->[0]) . "\n" }
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
