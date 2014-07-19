package AmuseWikiFarm::Archive::BookBuilder;

use utf8;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

use AmuseWikiFarm::Utils::Amuse qw/muse_filename_is_valid/;
use File::Spec;
use Cwd;
use File::MimeInfo::Magic qw/mimetype/;
use File::Copy qw/copy/;

has textlist => (is => 'rw',
                 isa => 'ArrayRef[Str]',
                 default => sub { [] },
                 trigger => \&_check_names,
                );

has error => (is => 'rw',
               isa => 'Str',
               default => sub { '' });

has filedir => (is => 'ro',
                isa => 'Str',
                default => sub {
                    return File::Spec->catdir(getcwd(), 'bbfiles');
                });

has files => (is => 'rw',
              isa => 'ArrayRef[Str]',
              default => sub { [] });

sub _check_names {
    my ($self, $list, $old_value) = @_;
    $self->error('');
    my @newlist;
    my @removed;
    foreach my $text (@$list) {
        if (muse_filename_is_valid($text)) {
            push @newlist, $text;
        }
        else {
            push @removed, $text;
        }
    }
    # modify the thing with the new list
    @$list = @newlist;
    if (@removed) {
        $self->error(join(' ', 'Removed', @removed));
    }
}

=head2 add_file($filepath)

Add a file to be merged into the the options. This has to be done
B<before> the call to C<validate_options>, because it's used to add
the cover.

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
    push @{ $self->files }, $file;
}

sub _generate_random_name {
    my ($self, $ext) = @_;
    my $basename = 'bb-' . int(rand(1000000)) . $ext;
    return File::Spec->rel2abs(File::Spec->catfile($self->filedir, $basename));
}

sub filename_is_valid {
    my ($self, $name) = @_;
    return muse_filename_is_valid($name);
}

sub add_text {
    my ($self, $text) = @_;
    if (muse_filename_is_valid($text)) {
        my $list = $self->textlist;
        push @$list, $text;
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

Return a copy of the text list.

=cut

sub texts {
    return [ @{ shift->textlist } ];
}

=head2 available_tex_options

Return an hashref with the available options and the validation sub,
which will return the correct value to pass to the template.

=head2 paper_sizes

Return an hash with available paper sizes. This needs coordination
with the template.

=head2 page_divs

Return an 

=cut

sub paper_sizes {
    my $self = shift;
    my %paper = (
                 a4 => 'A4 paper',
                 a5 => 'A5 paper',
                 a6 => 'A6 paper (also suitable for e-readers)',
                 letter => 'Letter paper',
                 '5.5in:8.5in' => 'Half Letter paper',
                 '4.25in:5.5in' => 'Quarter Letter paper',
                );
    return \%paper;
}

sub paper_sizes_sorted {
    return [qw/a4 a5 a6 letter 5.5in:8.5in 4.25in:5.5in/]
}

sub page_divs {
    my %divs =  map { $_ => $_ } (9..15);
    return \%divs;
}

sub font_sizes {
    my %sizes= map { $_ => $_ } (10..12);
    return \%sizes;
}

sub available_fonts {
    my $self = shift;
    my %fonts = reverse %{ $self->avail_fonts };
    return \%fonts;
}

sub avail_fonts {
    my %fonts = (
                 charis    => 'Charis SIL',
                 libertine => 'Linux Libertine O',
                 cmu       => 'CMU Serif',
                 paratype  => 'PT Serif',
                );
    return \%fonts;
}

sub avail_fonts_sorted {
    return [qw/libertine charis cmu paratype/];
}

sub schemas {
    my $self = shift;
    my %schemas = map { $_ => $_ } @{ $self->schemas_sorted };
    return \%schemas;
}

sub schemas_sorted {
    return [qw/2up 2down 2x4x2 2side/]
}

sub available_tex_options {
    my $self = shift;
    my %paper =     %{ $self->paper_sizes };
    my %divs  =     %{ $self->page_divs   };
    my %fontsizes = %{ $self->font_sizes  };
    my %fonts     = %{ $self->avail_fonts };   
    my $options = {
                   twoside => sub {
                       my $i = shift;
                       $i ? return 1 : return 0;
                   },
                   papersize => sub {
                       my $i = shift;
                       return unless defined $i;
                       $i = lc($i);
                       $paper{$i} ? return $i : return;
                   },
                   division => sub {
                       my $i = shift;
                       return unless defined $i;
                       $divs{$i} ? return $i : return;
                   },
                   fontsize => sub {
                       my $i = shift;
                       return unless defined $i;
                       $fontsizes{$i} ? return $i : return;
                   },
                   bcor => sub {
                       my $i = shift;
                       if ($i and $i =~ m/^([0-9]+)$/s) {
                           return $1 . 'mm';
                       }
                       else {
                           return '0mm';
                       }
                   },
                   mainfont => sub {
                       my $i = shift;
                       return unless defined $i;
                       $fonts{$i} ? return $fonts{$i} : return;
                   },
                   coverwidth => sub {
                       my $i = shift;
                       if ($i and $i =~ m/^([0-9]+)$/s) {
                           return sprintf('%.2f', $i / 100) . "\\textwidth";
                       }
                       else {
                           return "\\textwidth";
                       }
                   }
                  };
    return $options;
};

=head2 validate_options(\%params)

Validate the parameters passed and return an hashref with the template options.
All keys will be present.

=head2 validate_imposer_options(\%params);

Validate the parameters passed and return an hashref with the imposer options.
All keys will be present.

=cut

sub validate_options {
    my ($self, $params) = @_;
    my $options = $self->available_tex_options;
    my %safe;
    foreach my $k (keys %$options) {
        $safe{$k} = $options->{$k}->($params->{$k});
    }
    if (@{$self->files}) {
        # safe provided the C<add_files> has been used...
        $safe{cover} = $self->files->[0];
    }
    return \%safe;
}

sub validate_imposer_options {
    my ($self, $params) = @_;
    my %opts;
    return undef unless ($params->{imposed} && $params->{schema});

    if ($self->schemas->{ $params->{schema} }) {
        $opts{schema} = $params->{schema};
    }
    else {
        return undef;
    }
    if ($params->{signatures}) {
        $opts{signature} = '40-80';
    }
    if ($params->{cover}) {
        $opts{cover} = 1;
    }
    return \%opts;
}

__PACKAGE__->meta->make_immutable;

1;
