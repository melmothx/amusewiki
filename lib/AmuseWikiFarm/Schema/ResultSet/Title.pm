package AmuseWikiFarm::Schema::ResultSet::Title;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head1 NAME

AmuseWikiFarm::Schema::ResultSet::Title - Title resultset

=head1 METHODS

=cut


__PACKAGE__->load_components('Helper::ResultSet::Random');

use DateTime;
use AmuseWikiFarm::Log::Contextual;

=head2 published_all

RS with status set to C<published>, sorted by title.

=head2 published_or_deferred_all

RS with status C<published> or C<deferred>, sorted by title.

=head2 sorted_by_title

Order the RS by C<sorting_pos> and C<title>

=head2 specials_only

=head2 status_is_published

RS with status C<published>

=head2 status_is_published_or_deferred

RS with status C<published> or C<deferred>

=head2 texts_only

=cut

sub published_all {
    return shift->sorted_by_title->status_is_published;
}

sub published_or_deferred_all  {
    return shift->sorted_by_title->status_is_published_or_deferred;
}

sub texts_only {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.f_class" => 'text' });
}

sub specials_only {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.f_class" => 'special' });
}

sub status_is_published {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.status" => 'published' });
}

sub status_is_published_or_deferred {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.status" => [qw/published deferred/] });
}

sub status_is_published_or_deferred_with_teaser {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search([
                          { "$me.status" => 'published' },
                          {
                           "$me.status" => 'deferred',
                           "$me.teaser" => { '!=' => '' }
                          }
                         ]);
}

sub status_is_not_published {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.status" => { '!=' => 'published' } });
}

sub status_is_deferred {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.status" => 'deferred' });
}


sub sorted_by_title {
    return shift->order_by('title_asc');
}

sub sort_by_pubdate_desc {
    return shift->order_by('pubdate_desc');
}


=head2 published_texts

Result set with published titles (deleted set to empty string and
publication date in the past.

=head2 published_or_deferred_texts

Same as above, but including deferred texts.

=cut

sub published_texts {
    return shift->published_all->texts_only;
}

sub published_or_deferred_texts {
    return shift->published_or_deferred_all->texts_only;
}


=head2 published_specials

Resultset with published special pages, with the same criteria of
C<published_texts>.

=head2 published_or_deferred_specials

Same as above, but including deferred special pages..

=cut

sub published_specials {
    return shift->published_all->specials_only;
}

sub published_or_deferred_specials {
    return shift->published_or_deferred_all->specials_only;
}

=head2 random_text

Get a random row

=cut

sub random_text {
    my $self = shift;
    return $self->published_texts->rand->single;
}


=head2 text_by_uri

Find a published text by uri.

=cut

sub text_by_uri {
    my ($self, $uri) = @_;
    return $self->published_texts->by_uri($uri)->single;
}

=head2 special_by_uri

Find a published special by uri.

=cut

sub special_by_uri {
    my ($self, $uri) = @_;
    return $self->published_specials->by_uri($uri)->single;
}

sub by_uri {
    my ($self, $uri) = @_;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.uri" => $uri });
}

=head2 find_file($path)

Shortcut for

 $self->search({ f_full_path_name => $path })->single;

=cut

sub find_file {
    my ($self, $path) = @_;
    die "Bad usage" unless $path;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.f_full_path_name" => $path })->single;
}


=head2 latest($number_of_items)

Return the latest published text, ordered by publishing date. If no
argument is provided, return 50 titles (at max).

=cut

sub latest {
    my ($self, $items) = @_;
    $items ||= 50;
    die "Bad usage, a number is required" unless $items =~ m/^[1-9][0-9]*$/s;
    return $self->published_texts->sort_by_pubdate_desc->rows_number($items);
}

=head1 Admin-related queries

=head2 unpublished

Return the titles, specials included, with the status not set to 'published'

=cut

sub unpublished {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->status_is_not_published->sort_by_pubdate_desc;
}


=head2 deferred_to_publish($datetime)

Return the Title resultset with status C<deferred> and C<pubdate>
lesser than the L<DateTime> object passed to method.

=cut

sub deferred_to_publish {
    my ($self, $time) = @_;
    die unless $time && $time->isa('DateTime');
    my $format_time = $self->result_source->schema->storage->datetime_parser
      ->format_datetime($time);
    my $me = $self->current_source_alias;
    return $self->status_is_deferred->search({
                                              "$me.pubdate" => { '<' => $format_time },
                                             });
}

=head2 listing_tokens($lang)

Use HRI to pull the data and select only some columns.

Return an hashref with 3 keys: C<texts> with the list of texts and
separators, C<text_count> with the total number of texts, and C<pager>
with an arrayref with the first letter. This is language specific, so
you need to pass lang (defaulting to english).

=cut

sub listing_tokens_plain {
    my $self = shift;
    my @list = $self->search(undef,
                             {
                              columns => [qw/author title uri lang f_class status list_title/],
                              result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                             })->all;
    foreach my $row (@list) {
        my $status = delete $row->{status};
        unless ($status && $status eq 'published') {
            $row->{is_deferred} = 1;
        }
        $row->{list_title} ||= $row->{title};
        if ($row->{list_title} =~ m/(\w)/) {
            $row->{first_char} = $1;
            $row->{first_char} = uc($row->{first_char});
        }
        my $class = delete $row->{f_class};
        my $uri = delete $row->{uri};
        if ($class eq 'text') {
            $row->{full_uri} = "/library/$uri";
        }
        elsif ($class eq 'special') {
            $row->{full_uri} = "/special/$uri";
        }
        else {
            Dlog_warn { "$_ has unsupported f_class $class" };
        }
    }
    return \@list;
}

sub listing_tokens {
    my ($self, $lang) = @_;
    my $list = $self->listing_tokens_plain;
    my $collator = Unicode::Collate::Locale->new(locale => $lang || 'en',
                                                 level => 1);
    my @dummy = (0..9, 'A'..'Z');
    my (%map, @list_with_separators, @paging);
    my $current = '';
    my $counter = 0;
    my $grand_total = scalar(@$list);
    while (@$list) {
        my $item = shift @$list;
        if (defined $item->{first_char}) {
            unless (defined $map{$item->{first_char}}) {
              REPLACEL:
                foreach my $letter (@dummy) {
                    if ($collator->eq($item->{first_char}, $letter)) {
                        $map{$item->{first_char}} = $letter;
                        last REPLACEL;
                    }
                }
                unless (defined $map{$item->{first_char}}) {
                    $map{$item->{first_char}} = $item->{first_char};
                }
            }
            $item->{first_char} = $map{$item->{first_char}};

            # assert we didn't screw up
            die "This shouldn't happen, replacement not found"
              unless defined $item->{first_char};

            if ($current ne $item->{first_char}) {
                $counter++;
                $current = $item->{first_char};
                push @paging, {
                               anchor_name => $item->{first_char},
                               anchor_id => $counter,
                              };
                push @list_with_separators, {
                                             anchor_name => $item->{first_char},
                                             anchor_id => $counter,
                                            };
            }
        }
        push @list_with_separators, $item;
    }
    return { texts => \@list_with_separators,
             text_count => $grand_total,
             label_pager => \@paging };
}

sub older_than {
    my ($self, $dt) = @_;
    $dt ||= DateTime->now;
    my $format_time = $self->result_source->schema->storage->datetime_parser
      ->format_datetime($dt);
    my $me = $self->current_source_alias;
    return $self->search({ "$me.pubdate" => { '<' => $format_time } })->order_by('pubdate_desc');
}

sub newer_than {
    my ($self, $dt) = @_;
    $dt ||= DateTime->now;
    my $format_time = $self->result_source->schema->storage->datetime_parser
      ->format_datetime($dt);
    my $me = $self->current_source_alias;
    return $self->search({ "$me.pubdate" => { '>' => $format_time } })->order_by('pubdate_asc');
}

sub bookbuildable_by_uri {
    my ($self, $uri) = @_;
    return unless $uri;
    return $self->status_is_published_or_deferred->texts_only->by_uri($uri)->single;
}

sub _sorting_map {
    my $self = shift;
    my $me = $self->current_source_alias;
    my @default = ("$me.sorting_pos", "$me.title", "$me.id");
    return {
            sku_asc => {
                        priority => 1,
                        order_by => { -asc => [ "$me.sku", @default ] },
                        # loc("By sku ascending");
                        label => "By sku ascending",
                        key => 'sku',
                       },
            sku_desc => {
                         priority => 2,
                         order_by => { -desc => [ "$me.sku", @default ]},
                         # loc("By sku descending");
                         label => "By sku descending",
                         key => 'sku',
                        },
            title_asc => {
                          priority => 3,
                          order_by => { -asc => [ @default ]},
                          # loc("By title A-Z");
                          label => "By title A-Z",
                          key => 'title',
                         },
            title_desc => {
                           priority => 4,
                           order_by => { -desc => [ @default ] },
                           # loc("By title Z-A")
                           label => "By title Z-A",
                           key => 'title',
                          },
            pubdate_desc => {
                             priority => 5,
                             order_by => [
                                          { -desc => [ "$me.pubdate" ] },
                                          { -asc => [ @default ] }
                                         ],
                            # loc("Newer first")
                            label => "Newer first",
                             key => 'pubdate',
                            },
            pubdate_asc => {
                            priority => 6,
                            order_by => { -asc => [ "$me.pubdate", @default ] },
                            # loc("Older first")
                            label => "Older first",
                            key => 'pubdate',
                           },
            };
}
                   

sub available_sortings {
    my ($self, %opt) = @_;
    my $avail = $self->_sorting_map;
    my @out;
    foreach my $k (keys %$avail) {
        unless ($opt{sku}) {
            next if $avail->{$k}->{key} eq 'sku';
        }
        push @out, {
                    name => $k,
                    label => $avail->{$k}->{label} || die,
                    priority => $avail->{$k}->{priority} || die,
                   };
    }
    return sort { $a->{priority} <=> $b->{priority} } @out; 
}

sub order_by {
    my ($self, $order) = @_;
    my $map = $self->_sorting_map;
    my $order_by = $map->{title_desc}->{order_by};
    if ($order && $map->{$order}->{order_by}) {
        $order_by = $map->{$order}->{order_by};
    }
    # not hit
    die "$order doesn't map to anything" unless $order_by;
    return $self->search(undef, { order_by => $order_by });
}

sub page_number {
    my ($self, $page) = @_;
    return $self->search(undef, { page => $self->_check_integer($page) || 1 });
}

sub rows_number {
    my ($self, $rows) = @_;
    return $self->search(undef, { rows => $self->_check_integer($rows) || 10 });
}

sub _check_integer {
    my ($self, $i) = @_;
    # avoid big integers
    if ($i and $i =~ m/\A([1-9][0-9]{0,5})\z/) {
        return $i + 0;
    }
    else {
        return 0;
    }
}

sub static_index_tokens {
    my $self = shift;
    my $me = $self->current_source_alias;
    $self->search(undef,
                  {
                   result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                   collapse => 1,
                   join => { title_categories => 'category' },
                   order_by => ["$me.sorting_pos",  "$me.title", "$me.id" ],
                   columns => [
                               "$me.uri",
                               "$me.title",
                               "$me.f_archive_rel_path",
                               "$me.author",
                               "$me.lang",
                               "$me.sorting_pos",
                               "$me.pubdate",
                               "$me.text_size",
                               "$me.text_qualification",
                               "$me.slides",
                              ],
                   '+columns' => {
                                  'title_categories.title_id' => 'title_categories.title_id',
                                  'title_categories.category_id' => 'title_categories.category_id',
                                  'title_categories.category.uri' => 'category.uri',
                                  'title_categories.category.type' => 'category.type',
                                  'title_categories.category.name' => 'category.name',
                                  'title_categories.category.sorting_pos' => 'category.sorting_pos',
                                 }
                  });
}

sub with_missing_pages_qualification {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search([
                          { text_size => 0},
                          { text_qualification => [undef, ''] },
                         ]);
}

1;
