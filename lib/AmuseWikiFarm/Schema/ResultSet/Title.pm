package AmuseWikiFarm::Schema::ResultSet::Title;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

__PACKAGE__->load_components('Helper::ResultSet::Random');

=head2 published_all

All records in Title with the status set to 'published'

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



1;

