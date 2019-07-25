package AmuseWikiFarm::Schema::ResultSet::Category;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use AmuseWikiFarm::Log::Contextual;
use DBI qw/SQL_INTEGER/;

__PACKAGE__->load_components('Helper::ResultSet::Random');

=head1 NAME

AmuseWikiFarm::Schema::ResultSet::Category - Category resultset

=head1 METHODS

=head2 by_type($type)

Return the sorted categories of a given type.

=cut

sub sorted {
    my ($self) = @_;
    my $me = $self->current_source_alias;
    return $self->search(undef,
                         { order_by => [
                                        "$me.type",
                                        "$me.sorting_pos",
                                        "$me.name"
                                       ] });
}

sub by_type {
    my ($self, $type) = @_;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.type" => $type })->sorted;
}

sub with_active_flag_on {
    my ($self) = @_;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.active" => 1 });
}

sub inactive {
    my ($self) = @_;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.active" => 0 });
}

sub active_only {
    my ($self) = @_;
    return $self->with_texts->with_active_flag_on;
}

=head2 active_only_by_type($type)

Return the sorted categories of a given type (C<author> or C<topic>)
which have a text count greater than 0.

=cut

sub active_only_by_type {
    my ($self, $type) = @_;
    return $self->active_only->by_type($type);
}

=head2 with_texts(deferred => 0, sort => 'asc',  min_texts => 0);

=cut

sub with_texts {
    my ($self, %options) = @_;
    my $me = $self->current_source_alias;
    my $text_condition;
    if ($options{deferred}) {
        $text_condition =  { 'title.status' => [qw/published deferred/] };
    }
    elsif ($options{deferred_with_teaser}) {
        $text_condition = [
                           {
                            'title.status' => 'published'
                           },
                           {
                            'title.status' => 'deferred',
                            'title.teaser' => {'!=' => '' }
                           }
                          ];
    }
    else {
        $text_condition = { 'title.status' => 'published' };
    }
    Dlog_debug { "$_" } $text_condition;
    my $sorting = $options{sort} || 'asc';

    my @default_sorting = ("$me.sorting_pos", "$me.uri", "$me.id");
    my %sortings = (
                    'count-asc' => { -asc => [live_title_count => @default_sorting ] },
                    'count-desc'=> { -desc => [live_title_count => @default_sorting ] },
                    'desc' => { -desc => [ @default_sorting ]},
                    'asc' => { -asc => [ @default_sorting ]},
                    type => { -asc => [ "$me.type", @default_sorting ]},
                   );
    my $order = $sortings{$sorting} || $sortings{asc};

    my $limit = 0;
    if ($options{min_texts} and $options{min_texts} =~ m/\A([1-9][0-9]*)\z/) {
        $limit = $1;
        $limit--;
    }

    return $self->search($text_condition,
                         {
                          join => { title_categories => 'title'},
                          columns => [qw/id name uri type sorting_pos site_id/],
                          '+select' => [ {
                                          count => 'title.id',
                                          -as => 'live_title_count'
                                         } ],
                          '+as' => ["$me.text_count"],
                          distinct => 1,
                          order_by => $order,
                          having => \['count(title.id) > ?', [ { dbd_attrs => SQL_INTEGER }, $limit ]]
                         });
}

sub static_index_tokens {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({
                          'title.f_class' => 'text',
                          'title.status' => 'published',
                         },
                         {
                          result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                          collapse => 1,
                          join => { title_categories => 'title' },
                          order_by => ["$me.sorting_pos", "$me.name"],
                          columns => [
                                      "$me.uri",
                                      "$me.name",
                                      "$me.sorting_pos",
                                     ],
                          '+columns' => {
                                         'title_categories.title_id' => 'title_categories.title_id',
                                         'title_categories.category_id' => 'title_categories.category_id',
                                         'title_categories.title.uri' => 'title.uri',
                                         'title_categories.title.status' => 'title.status',
                                         'title_categories.title.sorting_pos' => 'title.sorting_pos',
                                         'title_categories.title.title' => 'title.title',
                                         'title_categories.title.slides' => 'title.slides',
                                         'title_categories.title.author' => 'title.author',
                                         'title_categories.title.f_archive_rel_path' => 'title.f_archive_rel_path',
                                        }
                         });
}

sub order_titles_by {
    my ($self, $key) = @_;
    my $order_by = $self->result_source
      ->schema->resultset('Category')->search(undef)
      ->search_related('title_categories')
      ->search_related('title')
      ->get_order_by($key);
    my $me = $self->current_source_alias;
    my @ordering = ("$me.sorting_pos", "$me.name");
    if (ref($order_by) eq 'ARRAY') {
        push @ordering, @$order_by;
    }
    else {
        push @ordering, $order_by;
    }
    Dlog_debug { "Order is $_" } \@ordering;
    return $self->search(undef,  { order_by => \@ordering });
}

=head2 by_type_and_uri($type, $uri)

Return the category which corresponds to type and uri

=cut

sub by_type_and_uri {
    my ($self, $type, $uri) = @_;
    return $self->by_type($type)->by_uri($uri)->single;
}

sub by_uri {
    my ($self, $uri) = @_;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.uri" => $uri });
}

=head2 active_only

Filter the categories which have text_count > 0

=head2 listing_tokens

Use HRI to pull the data and select only some columns.

=cut

sub hri {
    my $self = shift;
    return $self->search(undef, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' });
}

sub listing_tokens {
    my $self = shift;
    my @all = $self->hri;

    Dlog_debug { "Listing tokens are $_" } \@all;
    foreach my $row (@all) {
        $row->{full_uri} = join('/', '', 'category', $row->{type}, $row->{uri});
    }
    return \@all;
}

sub topics_only {
    return shift->by_type('topic');
}

sub authors_only {
    return shift->by_type('author');
}

sub by_full_uri {
    my ($self, $url) = @_;
    my @elements = grep { length($_) } split(/\//, $url);
    return if @elements < 2;
    my $uri = $elements[-1];
    my $type = $elements[-2];
    my %types = (
                 author => 'author',
                 topic => 'topic',
                );
    if ($type && $uri && $types{$type}) {
        return $self->by_type($type)->by_uri($uri)->single;
    }
    else {
        return;
    }
}

sub full_uri_name_mapping_hashref {
    my $self = shift;
    my %map;
    while (my $cat = $self->next) {
        $map{$cat->full_uri} = $cat->name;
    }
    return \%map;
}

1;

