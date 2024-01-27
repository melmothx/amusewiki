use utf8;
package AmuseWikiFarm::Schema::Result::Bookcover;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Bookcover

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

=head2 template

  data_type: 'varchar'
  is_nullable: 1
  size: 64

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
  "template",
  { data_type => "varchar", is_nullable => 1, size => 64 },
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


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2024-01-26 21:09:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Gfshihr4cfYIUiU1XR4Unw

use Path::Tiny;
use File::Copy::Recursive qw/dircopy/;
use AmuseWikiFarm::Utils::Paths;
use AmuseWikiFarm::Log::Contextual;
use Template::Tiny;
use IPC::Run qw(run);
use Cwd;
use DateTime;

sub working_dir {
    my $self = shift;
    my $root = AmuseWikiFarm::Utils::Paths::root_install_directory();
    my $bcroot = $root->child('bookcovers');
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
\bookcovercomponent{normal}{front}[15mm,15mm,15mm,0.2\partheight]{
\centering
[% IF author_muse %]
{\bfseries\LARGE\emph{[% author_muse %]}}
\vskip 0.1\partheight
[% END %]
{\Huge\bfseries [% title_muse %]}}
\bookcovercomponent{center}{spine}{
  \rotatebox[origin=c]{-90}{\bfseries [% IF author_muse %]\emph{[% author_muse %]}\quad\quad[% END %]
  [% title_muse %]}
}
\bookcovercomponent{normal}{back}[15mm,15mm,15mm,0.2\partheight]{[% back_text_muse %]}
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
    while ($body =~ m/\[\%\s*(([a-z_]+)_(int|muse|float|file))\s*\%\]/g) {
        my ($whole, $name, $type) = ($1, $2, $3);
        $tokens{$whole} = { name => $name, type => $type };
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

sub compose_class_header {
    my $self = shift;
    # built in for now
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
    return "\\documentclass[" . join(",", @opts) . "]{bookcover}\n";
}

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
    $outfile->spew_utf8($self->compose_class_header, $output);
    return $outfile;
}

sub produce_pdf {
    my $self = shift;
    # this should happen only in the jobber, where we fork. But in
    # case, return to the original directory.
    my $cwd = getcwd;
    my $wd = $self->working_dir;
    chdir $wd or die "Cannot chdir into $wd";
    my ($in, $out, $err);
    my @run = ("lualatex", '-interaction=nonstopmode', 'cover.tex');
    run \@run, \$in, \$out, \$err;
    chdir $cwd or die "Cannot chdir back into $cwd";
    # log_info { "Compilation: $out $err" };
    return {
            stdout => $out,
            stderr => $err,
            file => $wd->child('cover.pdf'),
           };
}


__PACKAGE__->meta->make_immutable;
1;
