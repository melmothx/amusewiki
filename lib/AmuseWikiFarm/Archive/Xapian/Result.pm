package AmuseWikiFarm::Archive::Xapian::Result;

use utf8;
use strict;
use warnings;
use Moo;
use Types::Standard qw/Maybe Object HashRef ArrayRef InstanceOf/;
use JSON::MaybeXS;
use AmuseWikiFarm::Log::Contextual;
use namespace::clean;

has pager => (is => 'ro',
              required => 1,
              isa => InstanceOf['Data::Page']);

has matches => (is => 'ro',
                required => 1,
                isa => ArrayRef[HashRef]);

has facets => (is => 'ro',
               required => 1,
               isa => HashRef[ArrayRef[HashRef]]);

has site => (is => 'ro',
             isa => Maybe[Object]);

has lh => (is => 'ro',
           isa => Maybe[Object]);

has authors => (is => 'lazy');

has topics => (is => 'lazy');

has dates => (is => 'lazy');

has pubdates => (is => 'lazy');

has num_pages => (is => 'lazy');

has text_types => (is => 'lazy');

sub facet_tokens {
    my $self = shift;
    my $lh = $self->lh;
    unless ($lh) {
        log_error { "Facet tokens called without the LH token, aborting" };
        return;
    }
    my @out = ({
                label => $lh->loc('Topics'),
                facets => $self->topics,
                name => 'filter_topic',
               },
               {
                label => $lh->loc('Authors'),
                facets => $self->authors,
                name => 'filter_author',
               },
               {
                label => $lh->loc('Date'),
                facets => $self->dates,
                name => 'filter_date',
               },
               {
                label => $lh->loc('Document type'),
                facets => $self->text_types,
                name => 'filter_qualification',
               },
               {
                label => $lh->loc('Published on this site'),
                facets => $self->pubdates,
                name => 'filter_pubdate',
               },
               {
                label => $lh->loc('Number of pages'),
                facets => $self->num_pages,
                name => 'filter_pages',
               });
    return \@out;
}

sub _build_authors {
    my $self = shift;
    my $list = $self->unpack_json_facets($self->facets->{author});
    $self->_add_category_labels($list);
    return $list;
}

sub _add_category_labels {
    my ($self, $list) = @_;
    my $site = $self->site or return;
    foreach my $i (@$list) {
        if (my $cat = $site->categories->by_full_uri($i->{value})) {
            $i->{label} = $cat->name;
        }
    }
}

sub _build_topics {
    my $self = shift;
    my $list = $self->unpack_json_facets($self->facets->{topic});
    $self->_add_category_labels($list);
    if (my $lh = $self->lh) {
        foreach my $i (@$list) {
            $i->{label} = $lh->loc($i->{label});
        }
    }
    return $list;
}

sub _build_dates {
    my $self = shift;
    my $list = $self->facets->{date};
    foreach my $i (@$list) {
        # these are decades, actually
        $i->{label} = $i->{value} . '-' . ($i->{value} + 9);
    }
    return $list;
}

sub _build_pubdates {
    my $self = shift;
    my $list = $self->facets->{pubdate};
    foreach my $i (@$list) {
        $i->{label} = $i->{value};
    }
    return $list;
}

sub _build_num_pages {
    my $self = shift;
    my $list = $self->facets->{pages};
    foreach my $i (@$list) {
        $i->{label} = $i->{value};
    }
    return $list;

}

sub _build_text_types {
    my $self = shift;
    my $list = $self->facets->{qualification};
    if (my $lh = $self->lh) {
        foreach my $i (@$list) {
            # loc('book'), loc('article')
            $i->{label} = $lh->loc($i->{value});
        }
    }
    return $list;
}



=head2 unpack_json_facets [INTERNAL]

This is horrid, but there is no multivalue and subclassing MatchSpy
leads to a beautiful segmentation fault (core dumped)

=cut

sub unpack_json_facets {
    my ($self, $arrayref) = @_;
    if ($arrayref) {
        my @raw = @$arrayref;
        my %out;
        while (@raw) {
            my $record = shift @raw;
            my @values = @{decode_json($record->{value})};
            my $count = $record->{count};
            foreach my $v (@values) {
                $out{$v} += $count;
            }
        }
        return [ sort { $b->{count} <=> $a->{count} || $a->{value} cmp $b->{value} }
                 map { +{ value => $_, count => $out{$_} } }
                 keys %out ];
    }
    return undef;
}

sub texts {
    my ($self) = @_;
    if (my $site = $self->site) {
        my @out;
        foreach my $match (@{$self->matches}) {
            if (my $text = $site->titles->texts_only->by_uri($match->{pagename})->single) {
                if ($text->can_be_indexed) {
                    push @out, $text;
                }
                else {
                    log_error { $site->id . ' ' . $match->{pagename} . ' is obsolete, removing'  };
                    $site->xapian->delete_text_by_uri($match->{pagename});
                }
            }
            else {
                log_error { $site->id . ' ' . $match->{pagename} . ' not found, removing'  };
                $site->xapian->delete_text_by_uri($match->{pagename});
            }
        }
        return \@out;
    }
    else {
        log_error { "Site object was not provided, cannot output a list of texts" };
        return;
    }
}

sub json_output {
    my $self = shift;
    my @out;
    if (my $texts = $self->texts) {
        my $base = $self->site->canonical_url;
        @out = map { +{
                       title => $_->title,
                       author => $_->author,
                       url => $base . $_->full_uri,
                       text_type => $_->text_qualification,
                       pages => $_->pages_estimated,
                      } } @$texts;
    }
    return \@out;
}

1;
