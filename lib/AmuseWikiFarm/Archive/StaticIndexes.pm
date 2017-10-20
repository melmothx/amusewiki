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
use Path::Tiny;
use Date::Parse;

# when we bump the version, we make sure to copy the files again.
sub version {
    return 2;
}

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
    $self->copy_static_files;
    my $site = $self->site;
    my $localizer = $site->localizer,
    my $lang = $site->locale;
    my $formats = $site->formats_definitions(localize => 1);
    my $prefix = $self->target_subdir->relative($site->repo_root);
    my @css_files = map { $prefix . '/' . $_ } $self->css_files;
    my @javascript_files = map { $prefix . '/' .  $_ } $self->javascript_files;
    my %todo = (
                $self->titles_file  => {
                                        list => $self->create_titles,
                                        title   => 'Titles',
                                       },
                $self->topics_file  => {
                                        list => $self->create_category_list('topic'),
                                        title   => 'Topics',
                                        category_listing => 1,
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
                            total_items => scalar(@{$todo{$file}{list}}),
                            site => $site,
                            formats => $formats,
                            lh => $localizer,
                            lang => $lang,
                            css_files => \@css_files,
                            javascript_files => \@javascript_files,
                            %{$todo{$file}}
                           },
                           $file,
                           { binmode => ':encoding(UTF-8)' })
          or die $tt->error;
    }
}

sub _in_tree_uri {
    my $title = shift;
    # same as Title::in_tree_uri
    my $relpath = $title->{f_archive_rel_path};
    $relpath =~ s![^a-z0-9]!/!g;
    $title->{in_tree_uri} = join('/', '.', $relpath, $title->{uri});
}

sub create_titles {
    my $self = shift;
    my $out;
    my $time = time();
    log_debug { "Creating titles" };
    my @texts = $self->site->titles->published_texts->static_index_tokens->all;
    my $locale = $self->site->locale || 'en';
    foreach my $title (@texts) {
        _in_tree_uri($title);
        $title->{pubdate_int} = str2time($title->{pubdate});
        my $dt = DateTime->from_epoch(epoch => $title->{pubdate_int},
                                      locale => $locale);
        $title->{pubdate} = $dt->format_cldr($dt->locale->date_format_medium);
        $title->{pages_estimated} = int($title->{text_size} / 2000);
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
                my $entry = $title->{title};
                _in_tree_uri($entry);
                push @titles, $entry;
            }
            if (@titles) {
                $cat->{sorted_titles} = \@titles;
                $cat->{titles_count} = scalar(@titles);
            }
        }
    }
    log_debug { "Created category listing in " . (time() - $time) . " seconds" };
    return \@cats;
}

sub javascript_files {
    my $self = shift;
    my @out = (
               path(js => 'jquery-1.11.1.min.js'),
               path(js => 'bootstrap.min.js'),
              );
    return @out;
}

sub css_files {
    my $self = shift;
    my $bootstrap = $self->site->bootstrap_theme;
    my @out = (path(css => "bootstrap.$bootstrap.css"),
               path(css => "font-awesome.min.css"),
               # path(css => "amusewiki.css")
              );
    return @out;
}

sub font_files {
    my $self = shift;
    my $src_dir = AmuseWikiFarm::Utils::Paths::static_file_location();
    my @out;
    foreach my $font ($src_dir->child('fonts')->children(qr{fontawesome}i)) {
        log_debug { "Found font file " };
        push @out, path(fonts => $font->basename);
    }
    return @out;
}

sub target_subdir {
    my $self = shift;
    return path($self->site->path_for_site_files, '__static_indexes');
}

sub copy_static_files {
    my $self = shift;
    my $target_dir = $self->target_subdir;
    my $update_needed = 1;
    if ($target_dir->child('.version')->exists and
        $target_dir->child('.version')->slurp eq $self->version) {
        log_debug { "No copy needed" };
        $update_needed = 0;
    }
    my $src_dir = AmuseWikiFarm::Utils::Paths::static_file_location();
    foreach my $dir (qw/css js fonts/) {
        path($target_dir, $dir)->mkpath;
    }
    my $out = 0;
    foreach my $file ($self->javascript_files,
                      $self->css_files,
                      $self->font_files) {
        my $src = $src_dir->child($file);
        my $target = $target_dir->child($file);
        if ($src->exists) {
            if ($target->exists and !$update_needed) {
                log_debug { "$target already exists" };
            }
            else {
                log_debug { "Copying $src to $target" };
                if ($target->basename eq 'font-awesome.css' or
                    $target->basename eq 'font-awesome.min.css') {
                    my $body = $src->slurp_raw;
                    $body =~ s/(\.(eot|woff|ttf|svg|woff2))\?[^']*v=[0-9]+\.[0-9]+\.[0-9]+[^']*'/$1'/g;
                    $target->spew_raw($body);
                }
                else {
                    $src->copy($target);
                }
                $out++;
            }
        }
        else {
            log_error { "$src doesn't exist!" };
        }
    }
    if ($out) {
        $target_dir->child('.version')->spew($self->version);
    }
    return $out;
}

__PACKAGE__->meta->make_immutable;

1;
