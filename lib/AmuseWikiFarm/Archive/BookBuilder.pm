package AmuseWikiFarm::Archive::BookBuilder;

use utf8;
use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use namespace::autoclean;

use AmuseWikiFarm::Utils::Amuse qw/muse_filename_is_valid/;
use File::Spec;
use Cwd;
use File::MimeInfo::Magic qw/mimetype/;
use File::Copy qw/copy/;
use Try::Tiny;


=head1 NAME

AmuseWikiFarm::Archive::BookBuilder -- Bookbuilder encapsulation

=head1 ACCESSORS

=head2 title

The title of the collection.

=cut

has title => (
              is => 'rw',
              isa => 'Maybe[Str]',
             );


=head2 textlist

An arrayref of valid AMW uris.

=cut

has textlist => (is => 'rw',
                 isa => 'ArrayRef[Str]',
                 default => sub { [] },
                );

=head2 filedir

The directory with BB files. Defaults to C<bbfiles>

=cut

has filedir => (is => 'ro',
                isa => 'Str',
                default => sub {
                    return File::Spec->catdir(getcwd(), 'bbfiles');
                });

=head2 coverfile

The uploaded filename for the cover image.

=cut

has coverfile => (is => 'rw',
                  isa => 'Maybe[Str]',
                  default => sub { undef });

=head2 Booleans

Mostly documented in L<Text::Amuse::Compile::Templates>. All of them
default to false.

=item twoside

=item nocoverpage

=item notoc

=item cover

=item imposed

If the imposition pass is required.

=cut

has twoside => (
                is => 'rw',
                isa => 'Bool',
                default => sub { 0 },
               );

has nocoverpage => (
                    is => 'rw',
                    isa => 'Bool',
                    default => sub { 0 },
                   );

has notoc => (
              is => 'rw',
              isa => 'Bool',
              default => sub { 0 },
             );

# imposer options
has cover => (
              is => 'rw',
              isa => 'Bool',
              default => sub { 1 },
             );

has imposed => (
                is => 'rw',
                isa => 'Bool',
                default => sub { 0 },
               );

=head2 schema

The schema to use for the imposer, if needed. Defaults to '2up'.
Beware that these are hardcoded in the template.

=cut

sub schema_values {
    return [qw/2up 2x4x2 2side/]
}

enum(SchemaType => __PACKAGE__->schema_values);

has schema => (
               is => 'rw',
               isa => 'SchemaType',
               default => sub { '2up' },
              );

=head2 papersize

The paper size to use.

=cut

sub papersizes {
    my $self = shift;
    my %paper = (
                 generic => 'Generic (fits in A4 and Letter)',
                 a4 => 'A4 paper',
                 a5 => 'A5 paper',
                 a6 => 'A6 paper (also suitable for e-readers)',
                 letter => 'Letter paper',
                 '5.5in:8.5in' => 'Half Letter paper',
                 '4.25in:5.5in' => 'Quarter Letter paper',
                );
    return \%paper;
}

sub papersize_values {
    return [qw/generic a4 a5 a6 letter 5.5in:8.5in 4.25in:5.5in/]
}

sub papersize_values_as_hashref {
    my $list = __PACKAGE__->papersize_values;
    my %pairs = map { $_ => 1 } @$list;
    return \%pairs;
}


enum(PaperType  => __PACKAGE__->papersize_values);

has papersize => (
                  is => 'rw',
                  isa => 'PaperType',
                  default => sub { 'generic' },
                 );

=head2 division

The division factor, as an integer, from 9 to 15.

=cut

sub divs_values {
    return [ 9..15 ];
}

enum(DivsType => __PACKAGE__->divs_values );

sub page_divs {
    my %divs =  map { $_ => $_ } @{ __PACKAGE__->divs_values };
    return \%divs;
}

has division => (
                 is => 'rw',
                 isa => 'DivsType',
                 default => sub { '12' },
                );

=head2 fontsize

The font size in point, from 10 to 12.

=cut


sub fontsize_values {
    return [ 10..12 ];
}

enum(FontSizeType => __PACKAGE__->fontsize_values);

has fontsize => (
                 is => 'rw',
                 isa => 'FontSizeType',
                 default => sub { '10' },
                );

=head2 bcor

The binding correction in millimeters, from 0 to 30.

=cut

sub bcor_values {
    return [0..30];
}

enum(BindingCorrectionType => __PACKAGE__->bcor_values );

has bcor => (
             is => 'rw',
             isa => 'BindingCorrectionType',
             default => sub { '0' },
            );

=head2 mainfont

The main font to use in the PDF output. This maps exactly to the
fc-list output, so be careful.

=head3 Auxiliary methods:

=head4 all_fonts

Return an arrayref of hashrefs, where each hashref has two keys:
C<name> and C<desc>.

=head4 available_fonts

Return an hashref, where keys and values are the same, with the name
of the font. This is used for validation.

=cut

sub all_fonts {
    my @fonts = ({
                  name => 'Linux Libertine O',
                  desc => 'Linux Libertine'
                 },
                 {
                  name => 'CMU Serif',
                  desc => 'Computer Modern',
                 },
                 {
                  name => 'TeX Gyre Termes',
                  desc => 'TeX Gyre Termes (Times)',
                 },
                 {
                  name => 'TeX Gyre Pagella',
                  desc => 'TeX Gyre Pagella (Palatino)',
                 },
                 {
                  name => 'TeX Gyre Schola',
                  desc => 'TeX Gyre Schola (Century)',
                 },
                 {
                  name => 'TeX Gyre Bonum',
                  desc => 'TeX Gyre Bonum (Bookman)',
                 },
                 {
                  name => 'Antykwa Poltawskiego',
                  desc => 'Antykwa Półtawskiego',
                 },
                 {
                  name => 'Antykwa Torunska',
                  desc => 'Antykwa Toruńska',
                 },
                 {
                  name => 'Charis SIL',
                  desc => 'Charis SIL (Bitstream Charter)',
                 },
                 {
                  name => 'PT Serif',
                  desc => 'Paratype (cyrillic)',
                 },
                );
    return \@fonts;
}

sub mainfont_values {
    my $list = __PACKAGE__->all_fonts;
    my @values = map { $_->{name} } @$list;
    return \@values;
}

sub available_fonts {
    my %fonts = ();
    foreach my $font (@{ __PACKAGE__->all_fonts }) {
        my $name = $font->{name};
        $fonts{$name} = $name;
    }
    return \%fonts;
}


enum(MainFontType => __PACKAGE__->mainfont_values );

has mainfont => (
                 is => 'rw',
                 isa => 'MainFontType',
                 default => sub { 'Linux Libertine O' },
                );

=head2 coverwidth

The cover width in text width percent. Default to 100%

=cut

sub coverwidths {
    my @values;
    my $v = 100;
    while ($v > 20) {
        push @values, $v;
        $v -= 5;
    }
    return \@values;
}

enum(CoverWidthType => __PACKAGE__->coverwidths);

has coverwidth => (
                   is => 'rw',
                   isa => 'CoverWidthType',
                   default => sub { '100' },
                  );

=head2 signature

The signature to use.

=cut

sub signature_values {
    return [qw/0 4 8 12 16 20 24 28 32 36 40 40-80/];
}

enum(SignatureType => __PACKAGE__->signature_values);

has signature => (
                   is => 'rw',
                   isa => 'SignatureType',
                   default => sub { '0' },
                  );

=head2 add_file($filepath)

Add a file to be merged into the the options.

=cut

sub add_file {
    my ($self, $filename) = @_;
    # copy it the filedir
    return unless -f $filename;
    die "Look like we're in the wrong path!, bbfiles dir not found"
      unless -d $self->filedir;
    my $mime = mimetype($filename) || "";
    my $ext;
    if ($mime eq 'image/jpeg') {
        $ext = '.jpg';
    }
    elsif ($mime eq 'image/png') {
        $ext = '.png';
    }
    else {
        return;
    }
    # find a random name
    my $file = $self->_generate_random_name($ext);
    while (-f $file) {
        $file = $self->_generate_random_name($ext);
    }
    copy $filename, $file or die "Copy $filename => $file failed $!";
    $self->coverfile($file);
}

sub _generate_random_name {
    my ($self, $ext) = @_;
    my $basename = 'bb-' . int(rand(1000000)) . $ext;
    return File::Spec->rel2abs(File::Spec->catfile($self->filedir, $basename));
}

=head2 add_text($text);

Add the text uri to the list of text. The URI will be checked with
C<muse_naming_algo>. Return true if the import succeed, false
otherwise.

=cut

sub add_text {
    my ($self, $text) = @_;
    return unless defined $text;
    if (muse_filename_is_valid($text)) {
        push @{ $self->textlist }, $text;
        return $text;
    }
    else {
        return;
    }
}

sub delete_text {
    my ($self, $digit) = @_;
    $self->_modify_list(delete => $digit);
}

sub move_up {
    my ($self, $digit) = @_;
    $self->_modify_list(up => $digit);
}

sub move_down {
    my ($self, $digit) = @_;
    $self->_modify_list(down => $digit);
}

sub _modify_list {
    my ($self, $operation, $digit) = @_;
    return unless ($digit and $digit =~ m/^[1-9][0-9]*$/);
    my $index = $digit - 1;
    return if $index < 0;
    my $list = $self->textlist;
    return unless exists $list->[$index];

    # deletion
    if ($operation eq 'delete') {
        splice(@$list, $index, 1);
        return;
    }

    # swapping
    my $replace = $index;

    if ($operation eq 'up') {
        $replace--;
        return if $replace < 0;
    }
    elsif ($operation eq 'down') {
        $replace++;
    }
    else {
        die "Wrong op $operation";
    }
    return unless exists $list->[$replace];

    # and swap
    my $tmp = $list->[$replace];
    $list->[$replace] = $list->[$index];
    $list->[$index] = $tmp;
    # all done
}

sub delete_all {
    shift->textlist([]);
}

=head2 texts

Return a copy of the text list as an arrayref.

=cut

sub texts {
    return [ @{ shift->textlist } ];
}

=head2 import_from_params(%params);

Populate the object with the provided HTTP parameters. Given the the
form has correct values, failing to import means that the params were
tampered or incorrect, so just ignore those.

=cut

sub import_from_params {
    my ($self, %params) = @_;
    # first the title.
    foreach my $method ($self->_accepted_params) {
        try {
            $self->$method($params{$method})
        } catch {
            my $error = $_;
            warn $error->message;
        };
    }
}

sub _accepted_params {
    return qw/title
              mainfont
              fontsize
              papersize
              division
              bcor
              coverwidth
              twoside
              notoc
              nocoverpage
              imposed
              signature
              schema
              cover/;
}

=head2 as_job

Main method to create a structure to feed the jobber for the building

=cut

sub as_job {
    my $self = shift;
    my $job = {
               text_list => $self->texts,
               title => $self->title || 'My collection', # enforce a title
               template_options => {
                                    twoside     => $self->twoside,
                                    nocoverpage => $self->nocoverpage,
                                    notoc       => $self->notoc,
                                    papersize   => $self->papersize,
                                    division    => $self->division,
                                    fontsize    => $self->fontsize,
                                    bcor        => $self->bcor . 'mm',
                                    mainfont    => $self->mainfont,
                                    coverwidth  => sprintf('%.2f', $self->coverwidth / 100),
                                    cover       => $self->coverfile,
                                   },
              };
    if ($self->imposed) {
        $job->{imposer_options} = {
                                   signature => $self->signature,
                                   schema    => $self->schema,
                                   cover     => $self->cover,
                                  };
    }
    return $job;
}

=head2 constructor_args

Return an hashref which, when dereferenced, will be be able to feed
the constructor and clone itself.

=cut

sub constructor_args {
    my $self = shift;
    my %args = (textlist => $self->texts);
    foreach my $method (qw/title
                           coverfile
                           twoside
                           nocoverpage
                           notoc
                           cover
                           imposed
                           schema
                           papersize
                           division
                           fontsize
                           bcor
                           mainfont
                           coverwidth
                           signature
                          /) {
        $args{$method} = $self->$method;
    }
    return \%args;
}


__PACKAGE__->meta->make_immutable;

1;
