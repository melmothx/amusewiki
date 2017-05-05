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
has css => (is => 'ro',
            lazy => 1,
            isa => 'Str',
            builder => '_build_css');

sub _build_css {
    my $self = shift;
    my $out = '';
    $self->tt->process($self->templates->css,
                       { html => 1 },
                       \$out) or die $self->tt->error;
    return $out;
}

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

 </div>
</body>
</html>
TEMPLATE
    return \$template;
}

sub list_template {
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
                                        list => $self->create_titles,
                                        title   => 'Titles',
                                        lang    => $self->lang,
                                        css     => $css,
                                        template => $self->list_template,
                                        formats => $self->formats,
                                       },
                $self->topics_file  => {
                                        list => $self->create_category_list($self->topics),
                                        title   => 'Topics',
                                        lang    => $self->lang,
                                        css     => $css,
                                        template => $self->category_template,
                                        formats => $self->formats,
                                       },
                $self->authors_file  => {
                                        list => $self->create_category_list($self->authors),
                                        title   => 'Authors',
                                        lang    => $self->lang,
                                        css     => $css,
                                        template => $self->category_template,
                                        formats => $self->formats,
                                       },
               );
    foreach my $file (keys %todo) {
        next unless $todo{$file}{list} && @{$todo{$file}{list}};
        $self->tt->process($todo{$file}{template},
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
    log_debug { "Created titles in " . (time() - $time) . " seconds" };
    return \@texts;
}

sub create_category_list {
    my ($self, $rs) = @_;
    my $time = time();
    log_debug { "Creating category listing" };
    my @cats = $rs->static_index_tokens->all;
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


__PACKAGE__->meta->make_immutable;

1;
