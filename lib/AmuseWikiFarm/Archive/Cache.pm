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
             isa => enum([qw/library category/]));

has subtype => (is => 'ro',
                isa => enum([qw/special text topic author/]));

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

has by_lang => (is => 'ro',
                isa => 'Bool');

has lang => (is => 'ro',
             isa => 'Str',
             default => sub { 'en' });

has no_caching => (is => 'ro',
                   isa => 'Bool');

sub _build_cache {
    my $self = shift;
    my $path = $self->cache_file;
    # try to load the cache
    if ($self->no_caching) {
        return $self->populate_cache;
    }
    my $cache;
    eval { $cache = Storable::retrieve($path) };
    if ($cache) {
        return $cache;
    }
    else {
        $cache = $self->populate_cache;
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
    if ($self->site_id =~ m/([0-9a-z]+)/) {
        my $site_id = $1;
        return File::Spec->catdir($self->cache_dir, $site_id);
    }
    else {
        die "Illegal site id!" . $self->site_id;
    }

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
    if ($self->by_lang) {
        push @dirs, 'by_lang';
    }
    if (my $lang = $self->lang) {
        if ($lang =~ m/([a-z]+)/) {
            push @dirs, $1;
        }
    }
    File::Path::make_path(File::Spec->catdir(@dirs));
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

sub text_count {
    my $self = shift;
    return $self->cache->{text_count} || 0;
}


sub populate_cache {
    my ($self) = @_;
    my $type = $self->type;
    die unless $type;
    die "No resultset passed, can't build the cache!" unless $self->resultset;
    my $cache;
    if ($type eq 'library') {
        $cache = $self->_cache_for_library;
    }
    elsif ($type eq 'category') {
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
    my (%map, @list_with_separators, @paging);
    my $current = '';
    my $counter = 0;
    my $grand_total = scalar(@$list);

    foreach my $item (@$list) {
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
    my $cache = { texts => \@list_with_separators,
                  text_count => $grand_total,
                  pager => \@paging };
    return $cache;
}

sub _cache_for_library {
    my $self = shift;
    my $rs = $self->resultset;
    my @list;
    while (my $row = $rs->next) {
        my %text = map { $_ => $row->$_ } qw/author title full_uri lang
                                             is_deferred/;
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
