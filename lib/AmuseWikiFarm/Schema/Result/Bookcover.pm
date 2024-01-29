use utf8;
package AmuseWikiFarm::Schema::Result::Bookcover;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Bookcover - Book Cover record

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<bookcover>

=cut

__PACKAGE__->table("bookcover");

=head1 ACCESSORS

=head2 bookcover_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 title

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 coverheight

  data_type: 'integer'
  default_value: 210
  is_nullable: 0

=head2 coverwidth

  data_type: 'integer'
  default_value: 148
  is_nullable: 0

=head2 spinewidth

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 flapwidth

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 wrapwidth

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 bleedwidth

  data_type: 'integer'
  default_value: 10
  is_nullable: 0

=head2 marklength

  data_type: 'integer'
  default_value: 5
  is_nullable: 0

=head2 foldingmargin

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=head2 created

  data_type: 'datetime'
  is_nullable: 0

=head2 compiled

  data_type: 'datetime'
  is_nullable: 1

=head2 zip_path

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 pdf_path

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 template

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 font_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 language_code

  data_type: 'varchar'
  is_nullable: 1
  size: 8

=head2 comments

  data_type: 'text'
  is_nullable: 1

=head2 session_id

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "bookcover_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "title",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "coverheight",
  { data_type => "integer", default_value => 210, is_nullable => 0 },
  "coverwidth",
  { data_type => "integer", default_value => 148, is_nullable => 0 },
  "spinewidth",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "flapwidth",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "wrapwidth",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "bleedwidth",
  { data_type => "integer", default_value => 10, is_nullable => 0 },
  "marklength",
  { data_type => "integer", default_value => 5, is_nullable => 0 },
  "foldingmargin",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "created",
  { data_type => "datetime", is_nullable => 0 },
  "compiled",
  { data_type => "datetime", is_nullable => 1 },
  "zip_path",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pdf_path",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "template",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "font_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "language_code",
  { data_type => "varchar", is_nullable => 1, size => 8 },
  "comments",
  { data_type => "text", is_nullable => 1 },
  "session_id",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</bookcover_id>

=back

=cut

__PACKAGE__->set_primary_key("bookcover_id");

=head1 RELATIONS

=head2 bookcover_tokens

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::BookcoverToken>

=cut

__PACKAGE__->has_many(
  "bookcover_tokens",
  "AmuseWikiFarm::Schema::Result::BookcoverToken",
  { "foreign.bookcover_id" => "self.bookcover_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 site

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Site>

=cut

__PACKAGE__->belongs_to(
  "site",
  "AmuseWikiFarm::Schema::Result::Site",
  { id => "site_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 user

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "AmuseWikiFarm::Schema::Result::User",
  { id => "user_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2024-01-28 08:28:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fVLEfhqffdDOy7MPywIHTg

use Path::Tiny;
use File::Copy::Recursive qw/dircopy/;
use AmuseWikiFarm::Utils::Paths;
use AmuseWikiFarm::Log::Contextual;
use Template::Tiny;
use IPC::Run qw(run);
use Cwd;
use DateTime;
use Archive::Zip ();
use Text::Amuse::Utils;
use Text::Amuse::Compile::Fonts;
use Text::Amuse::Compile::Fonts::Selected;

has fonts => (is => 'ro',
              isa => 'Object',
              lazy => 1,
              builder => '_build_fonts',
              handles => [qw/serif_fonts mono_fonts sans_fonts all_fonts/],
             );

sub _build_fonts {
    my $self = shift;
    return Text::Amuse::Compile::Fonts->new($self->site->fontspec_file);
}


sub working_dir {
    my $self = shift;
    my $root = AmuseWikiFarm::Utils::Paths::root_install_directory();
    my $bcroot = path($root, qw/bbfiles bookcovers/);
    $bcroot->mkpath unless $bcroot->exists;
    my $wd = $bcroot->child($self->bookcover_id);
    return $wd;
}

sub template_file {
    shift->working_dir->child('cover.tt');
}

sub create_working_dir {
    my $self = shift;
    my $template_file = $self->template_file;
    my $target = $template_file->parent;
    if (my $ttdir = $self->site->valid_ttdir) {
        if (my $template_dir = $self->template) {
            if ($template_dir =~ m/\A([a-z0-9]{3,})\z/) {
                my $src = path($ttdir, $1);
                if ($src->exists and $src->child('cover.tt')->exists) {
                    log_info { "Copying $src into $target" };
                    dircopy("$src", "$target");
                    return $target;
                }
            }
        }
    }
    # still here? using the default
    $target->mkpath;
    my $body = <<'LATEX';
% document class populated by us
\begin{document}
\begin{bookcover}
\bookcovercomponent{normal}{front}[0.1\partheight,0.1\partheight,0.1\partheight,0.1\partheight]{
\centering
[% IF author_muse_str %]
{\bfseries\itshape\LARGE [% author_muse_str %]\par}
\vskip 0.1\partheight
[% END %]
{\bfseries\Huge [% title_muse_str %]\par}
[% IF image_file %]
\vskip 0.1\partheight
\includegraphics[width=0.5\partwidth]{[% image_file %]}
[% END %]
}
\bookcovercomponent{center}{spine}{
  \rotatebox[origin=c]{-90}{\bfseries [% IF author_muse_str %]\emph{[% author_muse_str %]}\quad\quad[% END %]
  [% title_muse %]}
}
\bookcovercomponent{normal}{back}[0.1\partheight,0.1\partheight,0.1\partheight,0.1\partheight]{[% back_text_muse_body %]}
\end{bookcover}
\end{document}
LATEX
    $target->child('cover.tt')->spew_utf8($body);
    return $target;
}

sub parse_template {
    my $self = shift;
    my $tt = $self->template_file;
    # this is the simple TT one so we just check for the tokens used
    my $body = $tt->slurp_utf8;
    my %tokens;
    while ($body =~ m/\[\%\s*(([a-z_]+)_(int|muse_str|muse_body|float|file))\s*\%\]/g) {
        my ($whole, $name, $type) = ($1, $2, $3);
        $tokens{$whole} = { name => $name, type => $type, full_name => $whole };
    }
    return \%tokens;
}

sub populate_tokens {
    my $self = shift;
    my $tokens = $self->parse_template;
    foreach my $k (keys %$tokens) {
        $self->bookcover_tokens->find_or_create({
                                                 token_name => $k
                                                });
    }
}

sub update_from_params {
    my ($self, $params) = @_;
    Dlog_debug { "Updating from params: $_" } $params;
    my %update;
    foreach my $int (qw/
                           coverheight
                           coverwidth
                           spinewidth
                           flapwidth
                           wrapwidth
                           bleedwidth
                           marklength
                       /) {
        my $param = $params->{$int};
        if (defined $param and $param =~ m/\A(0|[1-9][0-9]*)\z/) {
            $update{$int} = $1;
        }
    }
    foreach my $bool (qw/foldingmargin/) {
        $update{$bool} = $params->{$bool} ? 1 : 0;
    }
    foreach my $str (qw/title comments/) {
        $update{$str} = $params->{$str} // '';
    }
    if (my @all_fonts = $self->all_fonts) {
        if (my $font = $params->{font_name}) {
            if (grep { $_->name eq $font } @all_fonts) {
                $update{font_name} = $font;
            }
        }
        $update{font_name} ||= $all_fonts[0]->name;
    }
    if (my $lang = $params->{language_code}) {
        if ($self->site->known_langs->{$lang}) {
            $update{language_code} = $lang;
        }
        else {
            $update{language_code} = 'en';
        }
    }
    if (%update) {
        Dlog_debug { "Updating bookcover with $_" } \%update;
        $self->update(\%update);
    }
    foreach my $token ($self->bookcover_tokens) {
        if (defined $params->{$token->token_name}) {
            $token->update_if_valid($params->{$token->token_name});
        }
    }
}

sub compose_preamble {
    my $self = shift;
    # built in for now
    my @preamble;
    # header
    {
        my @opts = ("12pt", "markcolor=black");
        foreach my $k (qw/
                             coverheight
                             coverwidth
                             spinewidth
                             flapwidth
                             wrapwidth
                             bleedwidth
                             marklength
                         /) {
            push @opts, "$k=" . $self->$k . 'mm';
        }
        foreach my $bool (qw/foldingmargin/) {
            push @opts, "$bool=" . ($self->$bool ? "true" : "false");
        }
        push @preamble, "\\documentclass[" . join(",", @opts) . "]{bookcover}";
    }
    # fonts
    if (my $choice = $self->font_name) {
        if (my @fonts = $self->all_fonts) {
            my ($selected) = grep { $_->name eq $choice } @fonts;
            $selected ||= $fonts[0];
            my $babel_lang = Text::Amuse::Utils::language_mapping()->{$self->language_code};
            my $final = Text::Amuse::Compile::Fonts::Selected->new(
                                                                   all_fonts => $self->fonts,
                                                                   size => 12,
                                                                   luatex => 1,
                                                                   main => $selected,
                                                                   mono => $selected,
                                                                   sans => $selected,
                                                                  );
            my $preamble = $final->compose_polyglossia_fontspec_stanza(lang => $babel_lang);
            # sorry for the hack. Remove everything before babel loading
            $preamble =~ s/\A.*(\\usepackage\[.*?\]\{babel\}.*)\z/$1/s;
            push @preamble, $preamble;
            push @preamble, "\\frenchspacing";
        }
    }
    push @preamble, "";
    return join("\n", @preamble);
}

# add the font + the language if the template doesn not have
# babel/polyglossia loaded.

sub write_tex_file {
    my $self = shift;
    my %vars;
    foreach my $token ($self->bookcover_tokens) {
        $vars{$token->token_name} = $token->token_value_for_template;
    }
    my $tfile = $self->template_file;
    my $input = $tfile->slurp_utf8;
    my $output;
    Dlog_debug { "$tfile: $input $_" } \%vars;
    Template::Tiny->new->process(\$input, \%vars, \$output);
    log_debug { "Output is $output" };
    my $outfile = $tfile->parent->child('cover.tex');
    $outfile->spew_utf8($self->compose_preamble, $output);
    return $outfile;
}

sub produce_pdf {
    my ($self, $logger) = @_;
    $logger ||= sub {};
    my $tex = $self->write_tex_file;
    # this should happen only in the jobber, where we fork. But in
    # case, return to the original directory.
    my $cwd = getcwd;
    my $wd = $self->working_dir;
    chdir $wd or die "Cannot chdir into $wd";
    my ($in, $out, $err);
    my @run = ("lualatex", '-interaction=nonstopmode', $tex->basename);
    my $ok = run \@run, \$in, \$out, \$err;
    chdir $cwd or die "Cannot chdir back into $cwd";
    # log_info { "Compilation: $out $err" };
    if ($ok) {
        my $pdf = "$tex";
        $pdf =~ s/\.tex/.pdf/;
        $self->compiled();
        $self->pdf_path($pdf);
        my $zipdir = Archive::Zip->new;
        if ($zipdir->addTree("$wd", "bookcover-" . $wd->basename) == Archive::Zip::AZ_OK) {
            my $zipfile = $wd->parent->child("bookcover-" . $wd->basename . ".zip");
            if ($zipdir->writeToFileNamed("$zipfile") == Archive::Zip::AZ_OK) {
                $self->update({
                               zip_path => "$zipfile",
                               pdf_path => "$pdf",
                               compiled => DateTime->now(time_zone => 'UTC'),
                              });
            }
            else {
                $logger->("Failed to write zip $zipfile");
            }
        }
        else {
            $logger->("Failed to create zip");
        }
    }
    return {
            stdout => $out,
            stderr => $err,
            success => $self->compiled ? 1 : 0,
           };
}

sub username {
    my $self = shift;
    if (my $user = $self->user) {
        return $user->username;
    }
    return;
}

__PACKAGE__->meta->make_immutable;
1;
