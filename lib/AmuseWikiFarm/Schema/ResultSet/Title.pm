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
    return shift->search({ f_class => 'text' });
}

sub specials_only {
    return shift->search({ f_class => 'special' });
}

sub status_is_published {
    return shift->search({ status => 'published' });
}

sub status_is_published_or_deferred {
    return shift->search({ status => [qw/published deferred/] });
}

sub sorted_by_title {
    return shift->search(undef,
                         { order_by => [qw/sorting_pos
                                           title/] });
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
    return $self->published_texts->single({ uri => $uri });
}

=head2 special_by_uri

Find a published special by uri.

=cut

sub special_by_uri {
    my ($self, $uri) = @_;
    return $self->published_specials->single({ uri => $uri });
}

=head2 find_file($path)

Shortcut for

 $self->search({ f_full_path_name => $path })->single;

=cut

sub find_file {
    my ($self, $path) = @_;
    die "Bad usage" unless $path;
    return $self->search({ f_full_path_name => $path })->single;
}


=head2 latest($number_of_items)

Return the latest published text, ordered by publishing date. If no
argument is provided, return 50 titles (at max).

=cut

sub latest {
    my ($self, $items) = @_;
    $items ||= 50;
    die "Bad usage, a number is required" unless $items =~ m/^[1-9][0-9]*$/s;
    return $self->published_texts->search({}, {
                                               rows => $items,
                                               order_by => { -desc => [qw/pubdate/] },
                                              });
}

=head1 Admin-related queries

=head2 unpublished

Return the titles, specials included, with the status not set to 'published'

=cut

sub unpublished {
    return shift->search( { status =>   { '!=' => 'published'    }, },
                          { order_by => { -desc => [qw/pubdate/] }, } );
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
    return $self->search({
                          status => 'deferred',
                          pubdate => { '<' => $format_time },
                         });

}

=head2 publish_deferred

Check and publish text which need publishing

=cut

sub publish_deferred {
    my $self = shift;
    my $now = DateTime->now;
    log_debug { "checking deferred titles for $now" };
    my $deferred = $self->deferred_to_publish($now);
    while (my $title = $deferred->next) {
        my $site = $title->site;
        my $file = $title->f_full_path_name;
        log_info { "Publishing $file for site " . $site->id };;
        $site->compile_and_index_files([ $file ]);
        log_info { "Done publishing $file" };
    }
}

=head2 listing_tokens($lang)

Use HRI to pull the data and select only some columns.

Return an hashref with 3 keys: C<texts> with the list of texts and
separators, C<text_count> with the total number of texts, and C<pager>
with an arrayref with the first letter. This is language specific, so
you need to pass lang (defaulting to english).

=cut

sub listing_tokens {
    my ($self, $lang) = @_;
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

    my $collator = Unicode::Collate::Locale->new(locale => $lang || 'en',
                                                 level => 1);
    my @dummy = (0..9, 'A'..'Z');
    my (%map, @list_with_separators, @paging);
    my $current = '';
    my $counter = 0;
    my $grand_total = scalar(@list);
    while (@list) {
        my $item = shift @list;
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
             pager => \@paging };
}

1;
