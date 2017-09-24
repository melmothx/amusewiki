package AmuseWikiFarm::Archive::StaticIndexes;

use strict;
use warnings;
use utf8;

use Moose;
use namespace::autoclean;
use Types::Standard qw/Object Str HashRef/;

use File::Spec;
use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Utils::Paths;
use Template;

=head1 NAME

AmuseWikiFarm::Archive::StaticIndexes -- Creating static indexes


=head1 ACCESSORS

The following attributes must be set in the constructor. They are not
mandatory and if not set the index generation will be skipped.

=head2 texts

The resultset object with the texts.

=head2 authors

The resultset object with the authors.

=head2 topics

The resultset object with the topics.

=cut

has site => (
             is => 'ro',
             required => 1,
             isa => Object,
            );

sub authors_file {
    my $self = shift;
    return File::Spec->catfile($self->site->repo_root, 'authors.html');
}

sub topics_file {
    my $self = shift;
    return File::Spec->catfile($self->site->repo_root, 'topics.html');
}

sub titles_file {
    my $self = shift;
    return File::Spec->catfile($self->site->repo_root, 'titles.html');
}

sub generate {
    my $self = shift;
    my $lang = $self->site->locale;
    my %todo = (
                $self->titles_file  => {
                                        list => $self->create_titles,
                                        title   => 'Titles',
                                        formats => $self->formats,
                                       },
                $self->topics_file  => {
                                        list => $self->create_category_list('topic'),
                                        title   => 'Topics',
                                        category_listing => 1,
                                        formats => $self->formats,
                                       },
                $self->authors_file  => {
                                        list => $self->create_category_list('author'),
                                        title   => 'Authors',
                                        category_listing => 1,
                                       },
               );
    my $tt = Template->new(
                           ENCODING => 'utf8',
                           INCLUDE_PATH => AmuseWikiFarm::Utils::Paths::templates_location()->stringify,
                          );
    foreach my $file (keys %todo) {
        next unless $todo{$file}{list} && @{$todo{$file}{list}};
        $tt->process('static-indexes.tt',
                           {
                            site => $self->site,
                            formats => $self->formats,
                            lh => $self->site->localizer,
                            lang => $lang,
                            %{$todo{$file}}
                           },
                           $file,
                           { binmode => ':encoding(UTF-8)' })
          or die $tt->error;
    }
}

sub create_titles {
    my $self = shift;
    my $out;
    my $time = time();
    log_debug { "Creating titles" };
    my @texts = $self->site->titles->published_texts->search(undef,
                                      {
                                       result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                                       collapse => 1,
                                       join => { title_categories => 'category' },
                                       order_by => [qw/me.sorting_pos me.title/],
                                       columns => [qw/me.uri
                                                      me.title
                                                      me.f_archive_rel_path
                                                      me.author
                                                      me.lang
                                                      me.sorting_pos
                                                     /],
                                       '+columns' => {
                                                      'title_categories.title_id' => 'title_categories.title_id',
                                                      'title_categories.category_id' => 'title_categories.category_id',
                                                      'title_categories.category.uri' => 'category.uri',
                                                      'title_categories.category.type' => 'category.type',
                                                      'title_categories.category.name' => 'category.name',
                                                      'title_categories.category.sorting_pos' => 'category.sorting_pos',
                                                     }
                                      })->all;
    foreach my $title (@texts) {
        # same as Title::in_tree_uri
        my $relpath = $title->{f_archive_rel_path};
        $relpath =~ s![^a-z0-9]!/!g;
        $title->{in_tree_uri} = join('/', '.', $relpath, $title->{uri});
        my (@authors, @topics);
        if ($title->{title_categories}) {
            my @sorted = sort {
                $a->{category}->{sorting_pos} <=> $b->{category}->{sorting_pos}
            } @{$title->{title_categories}};
            while (@sorted) {
                my $cat = shift @sorted;
                if ($cat->{category}->{type} eq 'topic') {
                    push @topics, $cat->{category};
                }
                elsif ($cat->{category}->{type} eq 'author') {
                    push @authors, $cat->{category};
                }
            }
        }
        if (@authors) {
            $title->{sorted_authors} = \@authors;
        }
        if (@topics) {
            $title->{sorted_topics} = \@topics;
        }
    }
    log_debug { "Created titles in " . (time() - $time) . " seconds" };
    return \@texts;
}

sub create_category_list {
    my ($self, $type) = @_;
    my $time = time();
    log_debug { "Creating category listing" };
    my @cats = $self->site->categories->by_type($type)->static_index_tokens->all;
    foreach my $cat (@cats) {
        if ($cat->{title_categories}) {
            my @titles;
            my @sorted = sort {
                $a->{title}->{sorting_pos} <=> $b->{title}->{sorting_pos}
            } @{delete $cat->{title_categories}};
            foreach my $title (@sorted) {
                push @titles, $title->{title};
            }
            if (@titles) {
                $cat->{sorted_titles} = \@titles;
            }
        }
    }
    log_debug { "Created category listing in " . (time() - $time) . " seconds" };
    return \@cats;
}

sub formats {
    my $self = shift;
    my $site = $self->site;
    # to be changed.
    return {
            muse => 1,
            pdf => $site->pdf,
            a4_pdf => $site->a4_pdf,
            lt_pdf => $site->lt_pdf,
            tex => $site->tex,
            epub => $site->epub,
            zip  => $site->zip,
           },
}


__PACKAGE__->meta->make_immutable;

1;
