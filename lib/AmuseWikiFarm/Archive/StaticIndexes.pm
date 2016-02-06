package AmuseWikiFarm::Archive::StaticIndexes;

use strict;
use warnings;
use utf8;

use Moose;
use namespace::autoclean;

use File::Spec;
use AmuseWikiFarm::Log::Contextual;

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

has texts => (
              is => 'ro',
              required => 0,
              isa => 'Object',
             );

has authors => (
                is => 'ro',
                required => 0,
                isa => 'Object',
               );

has topics => (
                is => 'ro',
                required => 0,
                isa => 'Object',
               );


has repo_root => (
                  is => 'ro',
                  required => 1,
                  isa => 'Str',
                 );

has tt => (
           is => 'ro',
           isa => 'Object',
           default => sub {
               require Template;
               return Template->new;        
           });


has templates => (
                  is => 'ro',
                  isa => 'Object',
                  default => sub {
                      require Text::Amuse::Compile::Templates;
                      return Text::Amuse::Compile::Templates->new;
                  });
has lang => (
             is => 'ro',
             isa => 'Str',
             default => sub { 'en' },
            );

has formats => (
                is => 'ro',
                isa => 'HashRef[Str]',
                default => sub {
                    return { muse => 1 }
                });

sub authors_file {
    my $self = shift;
    return File::Spec->catfile($self->repo_root, 'authors.html');
}

sub topics_file {
    my $self = shift;
    return File::Spec->catfile($self->repo_root, 'topics.html');
}

sub titles_file {
    my $self = shift;
    return File::Spec->catfile($self->repo_root, 'titles.html');
}

sub category_template {
    my $template = <<'TEMPLATE';
<ol>
[% FOREACH cat IN list %]
<li>
  <h4 id="cat-[% cat.uri %]">[% cat.name %]</h4>
  <ul>
    [% FOREACH text IN cat.sorted_titles %]
    <li>
      <a href="./titles.html#text-[% text.uri %]">[% text.title %]</a>
    </li>
    [% END %]
  </ul>
</li>
[% END %]
</ol>
TEMPLATE
    return \$template;
}

sub list_template {
    my $template = <<'TEMPLATE';
<ol>
  [% FOREACH text IN list %]
  <li>
    <div id="text-[% text.uri %]">
      <a href="[% text.in_tree_uri %].html">
        [% text.title %]
      </a>
      [%- IF text.author %] — [% text.author %] [% END %]
      [% IF text.lang %]      [[% text.lang %]] [% END %]
    </div>
    <div>
      [% IF formats.pdf %]
      <a href="[% text.in_tree_uri %].pdf">
        [PDF]
      </a>
      [% END %]
      [% IF formats.a4_pdf %]
      <a href="[% text.in_tree_uri %].a4.pdf">
        [A4 PDF]
      </a>
      [% END %]
      [% IF formats.lt_pdf %]
      <a href="[% text.in_tree_uri %].lt.pdf">
        [Letter PDF]
      </a>
      [% END %]
      [% IF formats.tex %]
      <a href="[% text.in_tree_uri %].tex">
        [TeX]
      </a>
      [% END %]
      [% IF formats.epub %]
      <a href="[% text.in_tree_uri %].epub">
        [EPUB]
      </a>
      [% END %]
      [% IF formats.muse %]
      <a href="[% text.in_tree_uri %].muse">
        [muse]
      </a>
      [% END %]
      [% IF formats.zip %]
      <a href="[% text.in_tree_uri %].zip">
        [ZIP]
      </a>
      [% END %]

    </div>
    [%- IF text.sorted_authors %]
    <ul style="list-style-type: none">
      [% FOREACH author IN text.sorted_authors %]
      <li style="display: inline">
        <a href="./authors.html#cat-[% author.uri %]">[% author.name %]</a>
      </li>
    [%- END -%]
    </ul>
    [% END %]

    [% IF text.sorted_topics %]
    <ul style="list-style-type: none">
      [% FOREACH topic IN text.sorted_topics %]
      <li style="display: inline">
        <a href="./topics.html#cat-[% topic.uri %]">[% topic.name %]</a>
      </li>
      [% END %]
    </ul>
    [% END %]
  </li>
  [% END %]
</ol>
TEMPLATE
    return \$template;
}

sub outer_template {
    # require content, css, lang
    my $template = <<'TEMPLATE';
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="[% lang %]" lang="[% lang %]">
<head>
  <meta http-equiv="Content-type" content="application/xhtml+xml; charset=UTF-8" />
  <title>[% title %]</title>
  <style type="text/css">
 <!--/*--><![CDATA[/*><!--*/
[% css %]
  /*]]>*/-->
    </style>
</head>
<body>
 <div id="page">
   <h3>[% title %]</h3>
   [% content %]
 </div>
</body>
</html>
TEMPLATE
    return \$template;
}

sub generate {
    my $self = shift;
    my $css = $self->css;
    my %todo = (
                $self->titles_file  => {
                                        content => $self->create_titles || '',
                                        title   => 'Titles',
                                        lang    => $self->lang,
                                        css     => $css,
                                       },
                $self->topics_file  => {
                                        content => $self->create_topics || '',
                                        title   => 'Topics',
                                        lang    => $self->lang,
                                        css     => $css,
                                       },
                $self->authors_file  => {
                                        content => $self->create_authors || '',
                                        title   => 'Authors',
                                        lang    => $self->lang,
                                        css     => $css,
                                       },
               );
    log_debug { "Inner templates done" };
    foreach my $file (keys %todo) {
        next unless $todo{$file}{content};
        $self->tt->process($self->outer_template,
                           $todo{$file},
                           $file,
                           { binmode => ':encoding(UTF-8)' })
          or die $self-tt->error;
    }
}

sub create_titles {
    my $self = shift;
    return unless $self->texts;
    my $out;
    my $time = time();
    log_debug { "Creating titles" };
    my @texts = $self->texts->search(undef,
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
    #    print Dumper($list);

    log_debug { "List created in " . (time() - $time) . " seconds" };
    $self->tt->process($self->list_template,
                       {
                        list => \@texts,
                        formats => $self->formats,
                       },
                       \$out) or die $self->tt->error;
    log_debug { "Titles done" };
    return $out;
                                   
}

sub _join_spec {
    return {
            collapse => 1,
            join => { title_categories => 'title' },
            order_by => [qw/me.sorting_pos me.name/],
            columns => [qw/me.uri
                           me.name
                          /],
            '+columns' => {
                           'title_categories.title_id' => 'title_categories.title_id',
                           'title_categories.category_id' => 'title_categories.category_id',
                           'title_categories.title.uri' => 'title.uri',
                           'title_categories.title.status' => 'title.status',
                           'title_categories.title.sorting_pos' => 'title.sorting_pos',
                           'title_categories.title.title' => 'title.title',
                          }
           };
}

sub create_topics {
    my $self = shift;
    return unless $self->topics;
    my $time = time();
    log_debug { "Creating topics list" };
    my $list = [ $self->topics->search(undef, $self->_join_spec)->all ];
    log_debug { "Done creating topics list in " . (time() - $time) . "seconds" };
    return $self->create_category_listing($list);
}

sub create_authors {
    my $self = shift;
    return unless $self->authors;
    my $time = time();
    log_debug { "Creating author list" };
    my $list = [ $self->authors->search(undef, $self->_join_spec)->all ];
    log_debug { "Done creating author list in " . (time() - $time) . "seconds" };
    return $self->create_category_listing($list);
}

sub create_category_listing {
    my ($self, $list) = @_;
    my $out;
    log_debug { "Start processing the category list" };
    $self->tt->process($self->category_template,
                       {
                        list => $list,
                       },
                       \$out) or die $self->tt->error;
    log_debug { "Done $list" };
    return $out;
}

sub css {
    my $self = shift;
    my $out = '';
    $self->tt->process($self->templates->css,
                       { html => 1 },
                       \$out) or die $self->tt->error;
    return $out;
}


__PACKAGE__->meta->make_immutable;

1;
