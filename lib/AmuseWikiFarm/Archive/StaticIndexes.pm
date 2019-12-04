package AmuseWikiFarm::Archive::StaticIndexes;

use strict;
use warnings;
use utf8;

use Moo;
use Types::Standard qw/Object Str HashRef ArrayRef/;

use File::Spec;
use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Utils::Paths;
use Template;
use Path::Tiny;
use Date::Parse;
use HTML::Packer;

# when we bump the version, we make sure to copy the files again.
sub version {
    return 4;
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

has category_types => (
                       is => 'lazy',
                       isa => ArrayRef[Object],
                      );

sub _build_category_types {
    my $self = shift;
    my @all = $self->site->site_category_types->active->ordered->all;
    return \@all;
}

sub output_file {
    my $self = shift;
    return path($self->site->repo_root, 'index.html');
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
    my $tt = Template->new(
                           ENCODING => 'utf8',
                           INCLUDE_PATH => AmuseWikiFarm::Utils::Paths::templates_location()->stringify,
                          );
    foreach my $old (qw/titles.html authors.html topics.html/) {
        my $f = path($site->repo_root, $old);
        if ($f->exists) {
            log_info { "Removing obsoleted file $f" };
            $f->remove;
        }
    }
    if (my $titles = $self->create_titles) {
        my $content;
        $tt->process('static-indexes.tt',
                           {
                            list => $titles,
                            title   => 'Titles',
                            categories => $self->category_types,
                            total_items => scalar(@$titles),
                            site => $site,
                            formats => $formats,
                            lh => $localizer,
                            lang => $lang,
                            css_files => \@css_files,
                            javascript_files => \@javascript_files,
                           },
                     \$content) or die $tt->error;
        my $packer = HTML::Packer->init();
        $packer->minify(\$content, {
                                    remove_comments => 1,
                                    do_javascript => 'best',
                                    do_stylesheet => 'minify',
                                   });
        $self->output_file->spew_utf8($content);
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
    my $site = $self->site;
    my @texts = $site->titles->published_texts
      ->static_index_tokens
      ->order_by($site->titles_category_default_sorting)
      ->all;
    my $locale = $site->locale || 'en';

    foreach my $title (@texts) {
        _in_tree_uri($title);
        $title->{pubdate_int} = str2time($title->{pubdate});
        my $dt = DateTime->from_epoch(epoch => $title->{pubdate_int},
                                      locale => $locale);
        $title->{pubdate} = $dt->format_cldr($dt->locale->date_format_medium);
        $title->{pages_estimated} = int($title->{text_size} / 2000);

        Dlog_debug { "Title is $_ " } $title;

        my %cat_by_type;
        if (my $ct = delete $title->{title_categories}) {
            my @sorted = sort {
                $a->{category}->{sorting_pos} <=> $b->{category}->{sorting_pos}
            } @$ct;
            Dlog_debug { "Categories are $_" } \@sorted;

          CATEGORY:
            while (@sorted) {
                my $cat_title = shift @sorted;
                # we don't really need the link here
                my $cat = $cat_title->{category};
                next CATEGORY unless $cat->{active};

                $cat_by_type{$cat->{type}} ||= [];
                push @{$cat_by_type{$cat->{type}}}, $cat;
            }
        }
        my @categories;
        foreach my $ctype (@{$self->category_types}) {
            push @categories, $cat_by_type{$ctype->category_type};
        }
        $title->{categories} = \@categories;
    }
    Dlog_debug { "Created titles in " . (time() - $time) . " seconds: $_" } \@texts;
    return \@texts;
}


sub javascript_files {
    my $self = shift;
    my @out = (
               path(js => 'jquery-1.11.1.min.js'),
               path(js => 'bootstrap.min.js'),
               path(js => datatables => 'datatables.min.js'),
              );
    return @out;
}

sub css_files {
    my $self = shift;
    my $bootstrap = $self->site->bootstrap_theme;
    my @out = (path(css => "bootstrap.$bootstrap.css"),
               path(css => "fork-awesome.min.css"),
               path(js => datatables => "datatables.min.css"),
               path(css => "amusewiki.css"),
              );
    return @out;
}

sub font_files {
    my $self = shift;
    my $src_dir = AmuseWikiFarm::Utils::Paths::static_file_location();
    my @out;
    foreach my $font ($src_dir->child('fonts')->children(qr{forkawesome}i)) {
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
    my $out = 0;
    foreach my $file ($self->javascript_files,
                      $self->css_files,
                      $self->font_files) {
        my $src = $src_dir->child($file);
        my $target = $target_dir->child($file);
        $target->parent->mkpath;
        if ($src->exists) {
            if ($target->exists and !$update_needed) {
                log_debug { "$target already exists" };
            }
            else {
                log_debug { "Copying $src to $target" };
                if ($target->basename eq 'fork-awesome.css' or
                    $target->basename eq 'fork-awesome.min.css') {
                    my $body = $src->slurp_raw;
                    # this is fragile but under our control.
                    $body =~ s/url
                               \(
                               (.+?) # anything non-greedy
                               (\?[^\)]*?)? # optional, anything non-greeding excluding closing parens
                               \) # closing parens.
                              /url($1)/gx;
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
