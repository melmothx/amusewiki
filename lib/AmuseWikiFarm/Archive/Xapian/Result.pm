package AmuseWikiFarm::Archive::Xapian::Result;

use utf8;
use strict;
use warnings;
use Moo;
use Types::Standard qw/Int Maybe Object HashRef ArrayRef InstanceOf Str Bool/;
use JSON::MaybeXS;
use AmuseWikiFarm::Log::Contextual;
use Data::Page;
use DateTime;
use Try::Tiny;
use namespace::clean;

has multisite => (is => 'ro', isa => Bool,  default => sub { 0 } );

has pager => (is => 'ro',
              default => sub { Data::Page->new },
              isa => InstanceOf['Data::Page']);

has max_categories => (is => 'ro',
                       default => sub { 30 },
                       isa => Int);

has matches => (is => 'ro',
                default => sub { [] },
                isa => ArrayRef[HashRef]);

has facets => (is => 'ro',
               default => sub { +{} },
               isa => HashRef[ArrayRef[HashRef]]);

has selections => (is => 'ro',
                   default => sub { +{} },
                   isa => HashRef[HashRef]);

# these are needed for the display

has site => (is => 'rw',
             isa => Maybe[Object]);

has lh => (is => 'rw',
           isa => Maybe[Object]);

has sites_map => (is => 'rw',
                  isa => Maybe[HashRef]);

has languages_map => (is => 'rw',
                      isa => Maybe[HashRef]);

has hostname_map => (is => 'rw',
                     isa => Maybe[HashRef]);

has show_deferred => (is => 'ro',
                      isa => Bool,
                      default => sub { 0 });

has authors => (is => 'lazy');

has topics => (is => 'lazy');

has languages => (is => 'lazy');

has hostnames => (is => 'lazy');

has dates => (is => 'lazy');

has pubdates => (is => 'lazy');

has num_pages => (is => 'lazy');

has text_types => (is => 'lazy');

has error => (is => 'ro', isa => Maybe[Str]);

sub facet_tokens {
    my $self = shift;
    return [] if $self->error;
    my $loc;
    if (my $lh = $self->lh) {
        $loc = sub { return $lh->loc(@_) };
    }
    elsif ($self->multisite) {
        # no loc if not passed
        $loc = sub { return @_ };
    }
    else {
        log_error { "Facet tokens called without the LH token, aborting" };
        return;
    }
    my @out;
    # topics and authors depend on the locale and on the origin site,
    # so if in a mixed environment it doesn't help much
    push @out, {
                label => $loc->('Site'),
                facets => $self->hostnames,
                name => 'filter_hostname',
               } if $self->multisite;

    if (($self->site && $self->site->multilanguage) or $self->multisite) {
        push @out, {
                    label => $loc->('Language'),
                    facets => $self->languages,
                    name => 'filter_language',
                   };
    }

    push @out, {
                label => $loc->('Topics'),
                facets => $self->topics,
                name => 'filter_topic',
               } unless $self->multisite;
    push @out, {
                label => $loc->('Authors'),
                facets => $self->authors,
                name => 'filter_author',
               } unless $self->multisite;
    push @out, {
                label => $loc->('Document type'),
                facets => $self->text_types,
                name => 'filter_qualification',
               },
               {
                label => $loc->('Number of pages'),
                facets => $self->num_pages,
                name => 'filter_pages',
               },
               {
                label => $loc->('Date'),
                facets => $self->dates,
                name => 'filter_date',
               },
               {
                label => $loc->('Publication date'),
                facets => $self->pubdates,
                name => 'filter_pubdate',
               };
    my $selections = $self->selections;
    foreach my $block (@out) {
        foreach my $facet (@{$block->{facets}}) {
            $facet->{active} = $selections->{$block->{name}}->{$facet->{value}};
        }
    }
    undef $loc; # shouldn't be needed, but still...
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
    my @uris;
    foreach my $i (@$list) {
        my $uri = (split(/\//, $i->{value}))[-1];
        push @uris, $uri;
    }
    my $map = $site->categories->by_uri(\@uris)->full_uri_name_mapping_hashref;
    foreach my $i (@$list) {
        if (my $label = $map->{$i->{value}}) {
            $i->{label} = $label;
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
    return [ sort  { $a->{value} <=> $b->{value} } @$list ];

}

sub _build_pubdates {
    my $self = shift;
    my $list = $self->facets->{pubdate};
    my %years;
    my $now = time();
    foreach my $epoch (@$list) {
        if ($now > $epoch->{value}) {
            my $date = DateTime->from_epoch(epoch => $epoch->{value});
            $years{$date->year} += $epoch->{count};
        }
    }
    my @out;
    foreach my $y (sort keys %years) {
        push @out, { value => $y, label => $y, count => $years{$y} };
    }
    Dlog_debug { "pudates became is $_" } \@out;
    return \@out;
}

sub _build_num_pages {
    my $self = shift;
    my $list = $self->facets->{pages};
    foreach my $i (@$list) {
        $i->{label} = $i->{value};
    }
    return [ sort { _first_number($a->{value}) <=> _first_number($b->{value}) } @$list ];
}

sub _build_languages {
    my $self = shift;
    my $list = $self->facets->{language};
    my $map;
    if ($self->languages_map) {
        $map = $self->languages_map;
    }
    elsif ($self->site) {
        $map = $self->site->known_langs;
    }
    else {
        $map = {};
    }
    foreach my $i (@$list) {
        $i->{label} = $map->{$i->{value}} || $i->{value};
    }
    return [ sort { $a->{value} cmp $b->{value} } @$list ];
}

sub _build_hostnames {
    my $self = shift;
    my $list = $self->facets->{hostname};
    my $map = $self->hostname_map || {};
    foreach my $i (@$list) {
        $i->{label} = $map->{$i->{value}} || $i->{value};
    }
    return [ sort { $b->{count} <=> $a->{count} or $a->{value} cmp $b->{value} } @$list ];
}

sub _first_number {
    my $str = shift;
    if ($str =~ m/([1-9][0-9]*)/) {
        return $1;
    }
    else {
        return 0;
    }
}

sub _build_text_types {
    my $self = shift;
    my $list = $self->facets->{qualification};
    my $lh = $self->lh;
    foreach my $i (@$list) {
        $i->{label} = $lh ? $lh->loc($i->{value}) : $i->{value};
    }
    return [ sort  { $a->{value} cmp $b->{value} } @$list ];
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
        my @out = sort { $b->{count} <=> $a->{count} || $a->{value} cmp $b->{value} }
          map { +{ value => $_, count => $out{$_} } }
          keys %out;
        splice(@out, $self->max_categories);
        return \@out;
    }
    return undef;
}

sub texts {
    my ($self) = @_;
    return [] if $self->error;
    my @out;
    foreach my $match (@{$self->matches}) {
        try {
            my $obj = AmuseWikiFarm::Archive::Xapian::Result::Text->new($match->{pagedata});
            push @out, $obj;
        } catch {
            my $err = $_;
            Dlog_error { "Cannot construct object from $_ " } $match->{pagedata};
        };
    }
    return \@out;
}

sub json_output {
    my $self = shift;
    my @out;
    return \@out if $self->error;
    my $sites_map = $self->sites_map;
    my $site = $self->site;
    if (!$sites_map and $site) {
        $sites_map = { $site->id => $site->canonical_url };
    }
    foreach my $match (@{$self->matches}) {
        my %text = %{$match->{pagedata}};
        $text{rank} = $match->{rank};
        $text{relevance} = $match->{relevance};
        if ($sites_map) {
            my $site_url = $sites_map->{$text{site_id}};
            foreach my $uri (grep { /_uri$/ } keys %text) {
                if ($text{$uri}) {
                    $text{$uri} = $site_url . $text{$uri};
                }
            }
            # back compat
            $text{url} = $text{full_uri};
            $text{text_type} = $text{text_qualification};
            $text{page} = $text{pages_estimate};
            $text{site_url} = $site_url;
            if ($text{pubdate_epoch} and $text{pubdate_epoch} < time()) {
                $text{pubdate_iso} = DateTime->from_epoch(epoch => $text{pubdate_epoch})->ymd;
            }
        }
        push @out, \%text;
    }
    return \@out;
}

1;
