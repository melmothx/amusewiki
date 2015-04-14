package AmuseWikiFarm::Archive::Cache;

use strict;
use warnings;
use utf8;

use Moose;
use namespace::autoclean;

use Moose::Util::TypeConstraints qw/enum/;
use File::Spec;
use Storable qw();
use Unicode::Collate::Locale;

=head1 NAME

AmuseWikiFarm::Archive::Cache

=head1 SYNOPSIS

Class to store and retrieve expensive query which hold a lot of data
(like topics, authors, titles lists).

  my $cache = AmuseWikiFarm::Archive::Cache->new(
                                                 site_id => '0blog0',
                                                 type => 'library-special',
                                                 resultset => $rs,
                                                );
  my $pager = $cache->pager;
  my $texts = $cache->texts;


=head1 CONSTRUCTOR

Takes the following keys:

=over 4

=item type

(e.g., library, category)

=item subtype

(e.g., author, topic, text, special)

=item site_id

(e.g., 'en')

=item resultset

The resultset to pull data in if the cache is not available.

=item paging

Boolean. Return the list with the pager separators if true.

=back

=cut

has type => (is => 'ro',
             isa => enum([qw/library-special library-text
                             category-topic category-author/]));

has subtype => (is => 'ro',
                isa => 'Str');

has site_id => (is => 'ro',
                isa => 'Str');

has cache_dir => (is => 'ro',
                  isa => 'Str',
                  default => sub {
                      return File::Spec->rel2abs(File::Spec->catdir(qw/var
                                                                       cache/));
                  });

has resultset => (is => 'ro',
                  isa => 'Object');

has cache => (is => 'ro',
              lazy => 1,
              builder => '_build_cache');

has lang => (is => 'ro',
             default => sub { 'en' });

sub _build_cache {
    my $self = shift;
    my $path = $self->cache_file;
    # try to load the cache
    my $cache;
    eval { $cache = Storable::retrieve($path) };
    if ($cache) {
        return $cache;
    }
    else {
        $cache = $self->populate_cache($path);
        # wrap in eval to mitigate race conditions.
        # Say we created the directory some lines ago, when calling cache_file,
        # but in the meanwhile the cache is cleared.
        # The thing would fail, because the is no parent directory. The eval
        # would prevent the thing to crash, and the result will not be cached.
        eval { Storable::lock_nstore($cache, $path) };
    }
    return $cache;
}


=head1 METHODS

=head2 pager

Return an arrayref for the pager

=head2 texts

Return an arrayref with the texts

=head2 clear_site_cache

Delete the cache for the site.

=head2 clear_all

Delete all the cache.

=cut

sub cache_site_dir {
    my $self = shift;
    die "No site id set, can't retrieve the cache directory for site"
      unless $self->site_id;
    return File::Spec->catdir($self->cache_dir, $self->site_id);
}

sub cache_file {
    my $self = shift;
    # to build a cache we need the following:
    my $type = $self->type;
    die "Missing type and subtype to build the cache!" unless $type;

    my $base = $self->cache_site_dir;
    my @dirs = ($base, $type);
    if (my $subtype = $self->subtype) {
        push @dirs, $subtype;
    }
    File::Path::make_path(File::Spec->catfile(@dirs));
    return File::Spec->catfile(@dirs, 'cache');
}

sub clear_site_cache {
    my $self = shift;
    File::Path::remove_tree($self->cache_site_dir, { keep_root => 1});
}

sub clear_all {
    my $self = shift;
    File::Path::remove_tree($self->cache_dir, { keep_root => 1});
}

sub pager {
    my $self = shift;
    return $self->cache->{pager};
}

sub texts {
    my $self = shift;
    return $self->cache->{texts};
}

sub populate_cache {
    my ($self, $path) = @_;
    my $type = $self->type;
    die unless $type;
    die "No resultset passed, can't build the cache!" unless $self->resultset;
    my $cache;
    if ($type eq 'library-special' or $type eq 'library-text') {
        $cache = $self->_cache_for_library;
    }
    elsif ($type eq 'category-topic' or $type eq 'category-author') {
        $cache = $self->_cache_for_category;
    }
    else {
        die "Wrong type $type!";
    }
    return $cache;
}

sub _create_library_cache_with_breakpoints {
    my ($self, $list) = @_;
    my $collator = Unicode::Collate::Locale->new(locale => $self->lang,
                                                 level => 1);
    my @dummy = (0..9, 'A'..'Z');
    my @list_with_separators;
    my @paging;
    my $current = '';
    my $counter = 0;
    foreach my $item (@$list) {
        if (defined $item->{first_char}) {
            my $first_char = $item->{first_char};
            foreach my $letter (@dummy) {
                if ($collator->eq($first_char, $letter)) {
                    $item->{first_char} = $first_char = $letter;
                    last;
                }
            }
            if ($current ne $first_char) {
                $counter++;
                $current = $first_char;
                push @paging, {
                               anchor_name => $first_char,
                               anchor_id => $counter,
                              };
                push @list_with_separators, {
                                             anchor_name => $first_char,
                                             anchor_id => $counter,
                                            };
            }
        }
        push @list_with_separators, $item;
    }
    my $cache = { texts => \@list_with_separators,
                  pager => \@paging };
    return $cache;
}

sub _cache_for_library {
    my $self = shift;
    my $rs = $self->resultset;
    my @list;
    while (my $row = $rs->next) {
        my %text = map { $_ => $row->$_ } qw/author title full_uri lang/;
        if ($row->list_title =~ m/(\w)/) {
            $text{first_char} = uc($1);
        }
        push @list, \%text;
    }
    return $self->_create_library_cache_with_breakpoints(\@list);
}

sub _cache_for_category {
    my $self = shift;
    my $rs = $self->resultset;
    my @list;
    while (my $row = $rs->next) {
        my %text = map { $_ => $row->$_ } qw/full_uri name text_count/;
        push @list, \%text;
    }
    my $cache = { texts => \@list };
    return $cache;
}


__PACKAGE__->meta->make_immutable;

1;
