package AmuseWikiFarm::Archive::BookBuilder;

use utf8;
use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use namespace::autoclean;

use Cwd;
use Data::Dumper;
use File::Spec;
use File::Temp;
use File::Copy qw/copy move/;
use File::MimeInfo::Magic qw/mimetype/;
use File::Copy qw/copy/;
use Try::Tiny;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Text::Amuse::Compile;
use PDF::Imposition;
use AmuseWikiFarm::Utils::Amuse qw/muse_filename_is_valid/;
use Text::Amuse::Compile::Webfonts;
use Text::Amuse::Compile::TemplateOptions;
use AmuseWikiFarm::Log::Contextual;

=head1 NAME

AmuseWikiFarm::Archive::BookBuilder -- Bookbuilder encapsulation

=head1 ACCESSORS

=head2 dbic

The L<AmuseWikiFarm::Schema> instance with the database. Needed if you
don't pass the C<site> directly.

=head2 site_id

The id of the site for text lookup from the db. Needed if you don't
pass the C<site> directly.

=head2 site

The L<AmuseWikiFarm::Schema::Result::Site> to which the texts belong.
If not provided, build lazily from C<dbic> and C<site_id>.

=head2 job_id

The numeric ID for the output basename.

=cut

has dbic => (is => 'ro',
             isa => 'Object');

has site_id => (is => 'ro',
                isa => 'Maybe[Str]');

has site => (is => 'ro',
             isa => 'Maybe[Object]',
             lazy => 1,
             builder => '_build_site');

has job_id => (is => 'ro',
               isa => 'Maybe[Str]');

enum(FormatType => [qw/epub pdf slides/]);

has format => (is => 'rw',
               isa => "FormatType",
               default => 'pdf');

sub _build_site {
    my $self = shift;
    if (my $schema = $self->dbic) {
        if (my $id = $self->site_id) {
            if (my $site  = $schema->resultset('Site')->find($id)) {
                return $site;
            }
        }
    }
    return undef;
}

=head2 paths and output

Defaults are sane.

=over 4

=item customdir

Alias for filedir.

=back

=cut


sub customdir {
    return shift->filedir;
}

has webfonts_rootdir => (is => 'ro',
                         isa => 'Str',
                         default => sub { 'webfonts' });

has webfonts => (is => 'ro',
                 isa => 'HashRef[Str]',
                 lazy => 1,
                 builder => '_build_webfonts');

sub _build_webfonts {
    my $self = shift;
    my $dir = $self->webfonts_rootdir;
    my %out;
    if ($dir and -d $dir) {
        opendir (my $dh, $dir) or die "Can't opendir $dir $!";
        my @fontdirs = grep { /^\w+$/ } readdir $dh;
        closedir $dh;
        foreach my $fontdir (@fontdirs) {
            my $path = File::Spec->catdir($dir, $fontdir);
            if (-d $path) {
                if (my $wf = Text::Amuse::Compile::Webfonts
                    ->new(webfontsdir => $path)) {
                    $out{$wf->family} = $wf->srcdir;
                }
            }
        }
    }
    return \%out;
}

sub jobdir {
    return shift->filedir;
}

=head2 error

Accesso to the error (set by the object).

=cut

has error => (is => 'rw',
              isa => 'Maybe[Str]');

=head2 total_pages_estimated

If the object has the dbic and the site object, then return the
current page estimation.

=cut

sub total_pages_estimated {
    my $self = shift;
    if (my $site = $self->site) {
        my $count = 0;
        foreach my $text (@{ $self->texts }) {
            if (my $title = $site->titles->text_by_uri($text)) {
                $count += $title->pages_estimated;
            }
        }
        return $count;
    }
    return 0;
}

=head2 epub

Build an EPUB instead of a PDF

=cut

sub epub {
    my $self = shift;
    return $self->format eq 'epub';
}

sub slides {
    my $self = shift;
    if ($self->format eq 'slides' and $self->can_generate_slides) {
        return 1;
    }
    else {
        return 0;
    }
}

# this is the default
sub pdf {
    my $self = shift;
    if ($self->format eq 'pdf' or
        (!$self->slides && !$self->epub)) {
        return 1;
    }
    else {
        return 0;
    }
}

has epubfont => (
                 is => 'rw',
                 isa => 'Maybe[Str]',
                );

=head2 title

The title of the collection.

=cut

has title => (
              is => 'rw',
              isa => 'Maybe[Str]',
             );


=head2 textlist

An arrayref of valid AMW uris. This arrayref possibly comes from the
session. So when we modify it, we end up modifying the session.
Unclear if this side-effect is welcome or not.

=cut

has textlist => (is => 'rw',
                 isa => 'ArrayRef[Str]',
                 default => sub { [] },
                );

=head2 filedir

The directory with BB files: C<bbfiles>. It's a constant

=cut

sub filedir { return 'bbfiles' }

=head2 coverfile

The absolute uploaded filename for the cover image.

=cut

has coverfile => (is => 'rw',
                  isa => 'Maybe[Str]',
                  default => sub { undef });

=head2 Booleans

Mostly documented in L<Text::Amuse::Compile::Templates>. All of them
default to false.

=item twoside

=item nocoverpage

=item headings

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

has headings => (
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
    return [qw/2up 2x4x2 2side 1x4x2cutfoldbind 4up/]
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

The font size in point, from 9 to 12.

=cut


sub fontsize_values {
    return [ 9..12 ];
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
    my @fonts = (Text::Amuse::Compile::TemplateOptions->all_fonts);
    return \@fonts;
}

sub all_main_fonts {
    my @fonts = (Text::Amuse::Compile::TemplateOptions->serif_fonts,
                 Text::Amuse::Compile::TemplateOptions->sans_fonts);
    return \@fonts;
}

sub all_serif_fonts {
    my @fonts = Text::Amuse::Compile::TemplateOptions->serif_fonts;
    return \@fonts;
}

sub all_sans_fonts {
    my @fonts = Text::Amuse::Compile::TemplateOptions->sans_fonts;
    return \@fonts;
}

sub all_mono_fonts {
    my @fonts = Text::Amuse::Compile::TemplateOptions->mono_fonts;
    return \@fonts;
}

sub all_fonts_values {
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


enum(FontType => __PACKAGE__->all_fonts_values );

has mainfont => (
                 is => 'rw',
                 isa => 'FontType',
                 default => sub { __PACKAGE__->all_serif_fonts->[0]->{name} },
                );

has monofont => (is => 'rw',
                 isa => 'FontType',
                 default => sub { __PACKAGE__->all_mono_fonts->[0]->{name} });

has sansfont => (is => 'rw',
                 isa => 'FontType',
                 default => sub { __PACKAGE__->all_sans_fonts->[0]->{name} });

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

=head2 signature_4up

=cut

sub signature_values {
    return [qw/0 40-80 4  8 12 16 20 24 28 32 36 40
                      44 48 52 56 60 64 68 72 76 80
              /];
}


sub signature_values_4up {
    return [qw/0 40-80  8 16 24 32 40
                       48 56 64 72 80
              /];
}



enum(SignatureType => __PACKAGE__->signature_values);

has signature => (
                   is => 'rw',
                   isa => 'SignatureType',
                   default => sub { '0' },
                 );


sub opening_values {
    return [qw/any right/];
}

enum(OpeningType => __PACKAGE__->opening_values);

has opening => (
                is => 'rw',
                isa => 'OpeningType',
                default => sub { 'any' },
               );


sub beamer_themes_values {
    return [ Text::Amuse::Compile::TemplateOptions->beamer_themes ];
}

enum(BeamerTheme => __PACKAGE__->beamer_themes_values);

sub beamer_color_themes_values {
    return [ Text::Amuse::Compile::TemplateOptions->beamer_colorthemes ];
}

enum(BeamerColorTheme => __PACKAGE__->beamer_color_themes_values);

has beamertheme => (is => 'rw',
                    isa => 'BeamerTheme',
                    default => sub { 'default' });

has beamercolortheme => (is => 'rw',
                         isa => 'BeamerColorTheme',
                         default => sub { 'dove' });


=head2 add_file($filepath)

Add a file to be merged into the the options.

=cut

sub remove_cover {
    my $self = shift;
    if (my $oldcoverfile = $self->coverfile_path) {
        if (-f $oldcoverfile) {
            log_debug { "Removing $oldcoverfile" };
            unlink $oldcoverfile;
        }
        else {
            log_warn { "$oldcoverfile was set but now is empty!" };
        }
        $self->coverfile(undef);
    }
}

sub add_file {
    my ($self, $filename) = @_;
    # copy it the filedir
    return unless defined $filename;
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
    $self->remove_cover;
    # find a random name
    my $file = $self->_generate_random_name($ext);
    $self->coverfile($file);
    copy $filename, $self->coverfile_path or die "Copy $filename => $file failed $!";

}

sub coverfile_path {
    my $self = shift;
    if (my $cover = $self->coverfile) {
        if (File::Spec->file_name_is_absolute($cover)) {
            return $cover;
        }
        return File::Spec->rel2abs(File::Spec->catfile($self->filedir, $cover));
    }
    else {
        return undef;
    }
}

sub _generate_random_name {
    my ($self, $ext) = @_;
    $ext ||= '';
    return 'bb-' . time() . $$ . int(rand(100000000)) . $ext;
}

=head2 add_text($text);

Add the text uri to the list of text. The URI will be checked with
C<muse_naming_algo>. Return true if the import succeed, false
otherwise.

=cut

sub add_text {
    my ($self, $text) = @_;
    return unless defined $text;
    # cleanup the error
    $self->error(undef);
    my $to_add;
    if (muse_filename_is_valid($text)) {
        # additional checks if we have the site.
        if (my $site = $self->site) {
            if (my $title = $site->titles->text_by_uri($text)) {
                my $limit = $site->bb_page_limit;
                my $total = $self->total_pages_estimated + $title->pages_estimated;
                if ($total <= $limit) {
                    $to_add = $text;
                }
                else {
                    # loc("Quota exceeded, too many pages")
                    $self->error('Quota exceeded, too many pages');
                }
            }
            else {
                # loc("Couldn't add the text")
                $self->error("Couldn't add the text");
            }
        }
        # no site check
        else {
            $to_add = $text;
        }
    }
    if ($to_add) {
        push @{ $self->textlist }, $to_add;
        return $to_add;
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

As a particular case, the 4up signature will be imported as signature
if the schema name is C<4up>.

=cut

sub import_from_params {
    my ($self, %params) = @_;
    if ($params{schema} and $params{schema} eq '4up') {
        $params{signature} = delete $params{signature_4up};
    }
    foreach my $method ($self->_main_methods) {
        # ignore coverfile when importing from the params
        next if $method eq 'coverfile';
        try {
            $self->$method($params{$method})
        } catch {
            my $error = $_;
            log_warn { $error->message };
        };
    }
    if ($params{removecover}) {
        $self->remove_cover;
    }
}

sub _main_methods {
    return qw/title
              format
              epubfont
              mainfont
              sansfont
              monofont
              beamercolortheme
              beamertheme
              fontsize
              coverfile
              papersize
              division
              bcor
              coverwidth
              twoside
              notoc
              nocoverpage
              headings
              imposed
              signature
              schema
              opening
              cover/;
}

=head2 as_job

Main method to create a structure to feed the jobber for the building

=cut

sub as_job {
    my $self = shift;
    my $job = {
               text_list => [ @{$self->texts} ],
               title => $self->title || 'My collection', # enforce a title
              };
    if (!$self->epub) {
        $job->{template_options} = {
                                    twoside     => $self->twoside,
                                    nocoverpage => $self->nocoverpage,
                                    headings    => $self->headings,
                                    notoc       => $self->notoc,
                                    papersize   => $self->papersize,
                                    division    => $self->division,
                                    fontsize    => $self->fontsize,
                                    bcor        => $self->bcor . 'mm',
                                    mainfont    => $self->mainfont,
                                    sansfont    => $self->sansfont,
                                    monofont    => $self->monofont,
                                    beamertheme => $self->beamertheme,
                                    beamercolortheme => $self->beamercolortheme,
                                    coverwidth  => sprintf('%.2f', $self->coverwidth / 100),
                                    opening     => $self->opening,
                                    cover       => $self->coverfile,
                                   };
    }
    if (!$self->epub && !$self->slides && $self->imposed) {
        $job->{imposer_options} = {
                                   signature => $self->signature,
                                   schema    => $self->schema,
                                   cover     => $self->cover,
                                  };
    }
    return $job;
}

=head2 compile($logger)

Compile 

=cut

sub produced_filename {
    my $self = shift;
    return $self->_produced_file($self->_produced_file_extension);
}

sub _produced_file_extension {
    my $self = shift;
    if ($self->epub) {
        return 'epub';
    }
    elsif ($self->slides) {
        return 'sl.pdf';
    }
    else {
        return 'pdf';
    }
}

sub sources_filename {
    my $self = shift;
    return 'bookbuilder-' . $self->_produced_file('zip');
}

sub _produced_file {
    my ($self, $ext) = @_;
    die unless $ext;
    my $base = $self->job_id;
    die "Can't call produced_filename if the job_id is not passed!" unless $base;
    return $base . '.' . $ext;
}


sub compile {
    my ($self, $logger) = @_;
    die "Can't compile a file without a job id!" unless $self->job_id;
    $logger ||= sub { print @_; };
    my $jobdir = File::Spec->rel2abs($self->jobdir);
    my $homedir = getcwd();
    die "In the wrong dir: $homedir" unless -d $jobdir;
    my $data = $self->as_job;
    # print Dumper($data);
    # first, get the text list
    my $textlist = $data->{text_list};

    # print $self->site->id, "\n";

    my %compile_opts = $self->site->compile_options;
    my $template_opts = $compile_opts{extra};

    # overwrite the site ones with the user-defined (and validated)
    foreach my $k (keys %{ $data->{template_options} }) {
        $template_opts->{$k} = $data->{template_options}->{$k};
    }

    # print Dumper($template_opts);

    my $bbdir    = File::Temp->newdir(CLEANUP => 1);
    my $basedir = $bbdir->dirname;
    my $makeabs = sub {
        my $name = shift;
        return File::Spec->catfile($basedir, $name);
    };

    # print "Created $basedir\n";

    my %archives;

    # validate the texts passed looking up the uri in the db
    my @texts;
    foreach my $text (@$textlist) {
        my $title = $self->site->titles->text_by_uri($text);
        unless ($title) {
            log_warn  { "Couldn't find $text\n" };
            next;
        }
        push @texts, $text;
        if ($archives{$text}) {
            next;
        }
        else {
            $archives{$text} = $title->filepath_for_ext('zip');
        }
    }
    die "No text found!" unless @texts;

    my %compiler_args = (
                         logger => $logger,
                         extra => $template_opts,
                         pdf => $self->pdf,
                         # the following is required to avoid the
                         # laziness of the compiler to recycle the
                         # existing .tex when there is only one text,
                         # so options will be ingnored.
                         tex => $self->pdf,
                         sl_tex => $self->slides,
                         sl_pdf => $self->slides,
                         epub => $self->epub,
                        );
    foreach my $setting (qw/luatex/) {
        if ($compile_opts{$setting}) {
            $compiler_args{$setting} = $compile_opts{$setting};
        }
    }
    if ($self->epub) {
        if (my $epubfont = $self->epubfont) {
            if (my $directory = $self->webfonts->{$epubfont}) {
                $compiler_args{webfontsdir} = $directory;
            }
        }
    }
    Dlog_debug { "archives: $_" } \%archives;
    # extract the archives

    foreach my $archive (keys %archives) {
        my $zipfile = $archives{$archive};
        my $zip = Archive::Zip->new;
        unless ($zip->read($zipfile) == AZ_OK) {
            log_warn { "Couldn't read $zipfile" };
            next;
        }
        $zip->extractTree($archive, $basedir);
    }
    if (my $coverfile = $self->coverfile_path) {
        my $coverfile_ok = 0;
        if (-f $coverfile) {
            my $coverfile_dest = $makeabs->($self->coverfile);
            log_debug { "Copying $coverfile to $coverfile_dest" };
            if (copy($coverfile, $coverfile_dest)) {
                $coverfile_ok = 1;
            }
        }
        unless ($coverfile_ok) {
            delete $compiler_args{extra}{cover};
        }
    }
    Dlog_debug { "compiler args are $_" } \%compiler_args;
    my $compiler = Text::Amuse::Compile->new(%compiler_args);
    my $outfile = $makeabs->($self->produced_filename);

    if (@texts == 1) {
        my $basename = shift(@texts);
        my $fileout   = $makeabs->($basename . '.' . $self->_produced_file_extension);
        $compiler->compile($makeabs->($basename . '.muse'));

        if (-f $fileout) {
            move($fileout, $outfile) or die "Couldn't move $fileout to $outfile";
        }
    }
    else {
        my $target = {
                      path => $basedir,
                      files => \@texts,
                      name => $self->job_id,
                      title => $data->{title},
                     };
        # compile
        $compiler->compile($target);
    }
    die "cwd changed. This is a bug" if getcwd() ne $homedir;
    die "$outfile not produced!\n" unless (-f $outfile);

    # imposing needed?
    if (!$self->epub and !$self->slides and
        $data->{imposer_options} and
        %{$data->{imposer_options}}) {

        my %args = %{$data->{imposer_options}};
        $args{file}    =  $outfile;
        $args{outfile} = $makeabs->($self->job_id. '.imp.pdf');
        $args{suffix}  = 'imp';
        print Dumper(\%args);
        my $imposer = PDF::Imposition->new(%args);
        $imposer->impose;
        # overwrite the original pdf, we can get another one any time
        copy($imposer->outfile, $outfile) or die "Copy to $outfile failed $!";
    }
    copy($outfile, $jobdir) or die "Copy $outfile to $jobdir failed $!";

    # create a zip archive with the temporary directory and serve it.
    my $zipdir = Archive::Zip->new;
    my $zipname = $self->sources_filename;
    my $ziproot = $zipname;
    $ziproot =~ s/\.zip$//;
    $zipdir->addTree($basedir, $ziproot) == AZ_OK
      or $logger->("Failed to produce a zip");
    $zipdir->writeToFileNamed(File::Spec->catfile($jobdir,
                                                  $zipname)) == AZ_OK
      or $logger->("Failure writing $zipname");
    die "cwd changed. This is a bug" if getcwd() ne $homedir;
    return $self->produced_filename;
}

=head2 produced_files

filenames of the BB files. They all reside in the bbfiles directory.

=cut


sub produced_files {
    my $self = shift;
    my @out;
    foreach my $f ($self->produced_filename,
                   $self->sources_filename) {
        push @out, $f;
    }
    if (my $cover = $self->coverfile) {
        push @out, $cover;
    }
    return @out;
}

=head2 serialize

Return an hashref which, when dereferenced, will be be able to feed
the constructor and clone itself.

=cut

sub serialize {
    my $self = shift;
    my %args = (textlist => $self->texts);
    foreach my $method ($self->_main_methods) {
        $args{$method} = $self->$method;
    }
    return \%args;
}

sub available_webfonts {
    my $self = shift;
    my @fonts = sort keys %{ $self->webfonts };
    return \@fonts;
}

sub can_generate_slides {
    my $self = shift;
    my @texts = @{$self->texts};
    if (@texts == 1 and $self->site) {
        if (my $text = $self->site->titles->text_by_uri($texts[0])) {
            return $text->slides;
        }
    }
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;
