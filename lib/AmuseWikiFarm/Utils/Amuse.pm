package AmuseWikiFarm::Utils::Amuse;
use utf8;
use strict;
use warnings;

use Data::Dumper;
use File::Spec;
use File::Basename;
use Text::Amuse::Functions qw/muse_fast_scan_header/;
use HTML::Entities qw/decode_entities/;
use Encode;
use Digest::MD5 qw/md5_hex/;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw/muse_file_info/;

=head2 muse_file_info($file, $site_id)

Scan the header of the file $file and collect all the relevant
informations, returning them as a hashref. It includes also the file
attributes, like timestamp, paths, etc.

The result is suitable to feed the database, so see
L<AmuseWikiFarm::Schema::Result::Title> for the returned keys and the
AmuseWiki manual for the list of supported and defined directives.

Special cases:

LISTtitle in the header will map to C<list_title>, defaulting to
C<title>, where any leading non-word characters are stripped (which is
the meaning of the LISTtitle).

This function makes sense only in a full installation of AmuseWiki, so
if the files are not in the right path, the indexing is skipped.

=cut

sub muse_file_info {
    my ($file, $site_id) = @_;
    die "$file not found!" unless -f $file;
    $site_id ||= 'default';
    my $details = _parse_muse_file($file);
    return unless $details;

    # TODO
    my $authors = delete $details->{SORTauthors};
    unless (defined($authors)) {
        $authors = $details->{author};
    }

    # TODO
    delete $details->{SORTtopics};

    # TODO fixed categories, to lookup in tables, space separated
    delete $details->{cat};

    my $title_order_by = delete $details->{LISTtitle};
    if (defined $title_order_by and length($title_order_by)) {
        $details->{list_title} = $title_order_by;
    }
    else {
        $title_order_by = $details->{title};
        if (defined($title_order_by) and $title_order_by =~ m/\w/) {
            $title_order_by =~ s/^[\W]+//;
            $details->{list_title} = $title_order_by;
        }
    }

    # check if the title exists
    unless ($details->{title}) {
        warn "$file has no title! Setting deletion\n";
        $details->{deleted} ||= "Missing title";
    }

    $details->{site_id} = $site_id;
    $details->{uri} = $details->{f_name};
    return $details;
}

sub _parse_muse_file {
    my $file = shift;
    unless (File::Spec->file_name_is_absolute($file)) {
        $file = File::Spec->rel2abs($file);
    }
    my ($name, $path, $suffix) = fileparse($file, ".muse");
    unless ($suffix) {
        warn "$file is not a muse file!";
        return;
    }

    unless ($name =~ m/^[0-9a-z]+[0-9a-z-]*[0-9a-z]+$/) {
        warn "$file has not a sane name!";
        return;
    }
    my @dirs = File::Spec->splitdir($path);
    @dirs = grep { $_ ne '' } @dirs;
    unless (@dirs >= 2) {
        warn "$file is not in the correct path!";
        return;
    }
    my @relpath = ($dirs[$#dirs-1], $dirs[$#dirs]);
    unless ($relpath[0] =~ m/^[0-9a-z]$/s and
            $relpath[1] =~ m/^[0-9a-z]{2}$/s) {
        warn "$file is not in the correct path:" . Dumper(\@relpath);
        return;
    }


    # scan the directives;
    my $directives = muse_fast_scan_header($file, 'html');
    unless ($directives && %$directives) {
        # title is mandatory?
        warn "$file couldn't be parsed by muse_fast_scan_header\n";
        return;
    }
    # just to be sure, check that the keys have not an underscore

    foreach my $k (keys %$directives) {
        die "Got $k directive with underscore in $file" unless index($k, '_') < 0;
    }

    # we don't get clashes with the parsing of the muse file because
    # directives have not underscors in them

    my %out = (
               %$directives,
               f_path => $path,
               f_name => $name,
               f_archive_rel_path => File::Spec->catdir(@relpath),
               f_timestamp => _get_mtime($file),
               f_full_path_name  => $file,
              );

    return \%out;
}


=head2 transliteration_table

Returns an hashref with the transliteration table.

=cut

sub transliteration_table  {

    my %translitterationtable =
  (
   # cyrillyc
   'а' => 'a',  'А' => 'a',    'р' => 'r',  'Р' => 'r',   
   'б' => 'b',  'Б' => 'b',    'с' => 's',  'С' => 's',   
   'в' => 'v',  'В' => 'v',    'т' => 't',  'Т' => 't',   
   'г' => 'g',  'Г' => 'g',    'у' => 'u',  'У' => 'u',   
   'д' => 'd',  'Д' => 'd',    'ф' => 'f',  'Ф' => 'f',   
   'е' => 'e',  'Е' => 'e',    'х' => 'h',  'Х' => 'h',   
   'ё' => 'e',  'Ё' => 'e',    'ц' => 'c',  'Ц' => 'c',   
   'ж' => 'j',  'Ж' => 'j',    'ч' => 'ch', 'Ч' => 'ch',  
   'з' => 'z',  'З' => 'z',    'ш' => 'sh', 'Ш' => 'sh',  
   'и' => 'i',  'И' => 'i',    'щ' => 'sch','Щ' => 'sch', 
   'й' => 'j',  'Й' => 'j',    'ь' => '',  'Ь' => '',   
   'к' => 'k',  'К' => 'k',    'ы' => 'y',  'Ы' => 'y',   
   'л' => 'l',  'Л' => 'l',    'ъ' => '',  'Ъ' => '',   
   'м' => 'm',  'М' => 'm',    'э' => 'e',  'Э' => 'e',   
   'н' => 'n',  'Н' => 'n',    'ю' => 'yu', 'Ю' => 'yu',  
   'о' => 'o',  'О' => 'o',    'я' => 'ya', 'Я' => 'ya',  
   'п' => 'p',  'П' => 'p', 

   # macedonian cyrl
   'ѓ' => 'dj',  'Ѓ' => 'dj',
   'ѕ' => 'dz',  'Ѕ' => 'dz',
   'ѝ' => 'i',   'Ѝ' => 'i',
   'ј' => 'j',   'Ј' => 'j',
   'љ' => 'lj',  'Љ' => 'lj',
   'њ' => 'nj',  'Њ' => 'nj',
   'ќ' => 'kj',  'Ќ' => 'kj',
   'џ' => 'dzh', 'Џ' => 'dzh',
   'Ѐ' => 'e',   'ѐ' => 'e',
   # the latin
   'á' => 'a',  'í' => 'i',  'ù' => 'u',  'æ' => 'ae',
   'Á' => 'a',  'ì' => 'i',  'ü' => 'u',  'Æ' => 'ae',
   'à' => 'a',  'Í' => 'i',  'ú' => 'u',
   'À' => 'a',  'Ì' => 'i',  'ū' => 'u',
   'È' => 'e',  'ò' => 'o',  'Ū' => 'u',
   'É' => 'e',  'ó' => 'o',  'Ù' => 'u',
   'Ë' => 'e',  'ō' => 'o',  'Ü' => 'u',
   'ë' => 'e',  'Ō' => 'o',  'Ú' => 'u',
   'é' => 'e',  'Ò' => 'o',  'ç' => 'c',
   'è' => 'e',  'Ó' => 'o',  'Ç' => 'c', 
   # finnish
   'ä' => 'a', 'Ä' => 'a',
   'Å' => 'a', 'å' => 'a',
   'ö' => 'o', 'Ö' => 'o',
   # other northen
   'ø' => 'o',  'õ' => 'o', 
   'Ø' => 'o',  'Õ' => 'o', 
   # croatian/serbian
    'č' => 'c' , 'Č' => 'c',
    'ć' => 'c' , 'Ć' => 'c',
    'ž' => 'z' , 'Ž' => 'z',
    'š' => 's' , 'Š' => 's',
    'đ' => 'dj', 'Đ' => 'dj',
    'â' => 'a' , 'Â' => 'a',
    'ê' => 'e' , 'Ê' => 'e',
    'î' => 'i' , 'Î' => 'i',
    'ô' => 'o' , 'Ô' => 'o',
    'û' => 'u' , 'Û' => 'u',
    'ā' => 'a' , 'Ā' => 'a',

   # polish, from http://en.wikipedia.org/wiki/Polish_alphabet
   'Ę' => 'e', 	'ę' => 'e',
   'Ł' => 'l',  'ł' => 'l',
   'Ń' => 'n', 	'ń' => 'n',
   'Ś' => 's',  'ś' => 's',
   'Ź' => 'z',  'ź' => 'z',
   'Ż' => 'z',  'ż' => 'z',

   # ascii
   'A' => 'a',  'a' => 'a',   '0' => '0',   
   'B' => 'b',  'b' => 'b',   '1' => '1',   
   'C' => 'c',  'c' => 'c',   '2' => '2',   
   'D' => 'd',  'd' => 'd',   '3' => '3',   
   'E' => 'e',  'e' => 'e',   '4' => '4',   
   'F' => 'f',  'f' => 'f',   '5' => '5',   
   'G' => 'g',  'g' => 'g',   '6' => '6',   
   'H' => 'h',  'h' => 'h',   '7' => '7',   
   'I' => 'i',  'i' => 'i',   '8' => '8',   
   'J' => 'j',  'j' => 'j',   '9' => '9',   
   'K' => 'k',  'k' => 'k',   
   'L' => 'l',  'l' => 'l',   
   'M' => 'm',  'm' => 'm',   
   'N' => 'n',  'n' => 'n',   
   'O' => 'o',  'o' => 'o',   
   'P' => 'p',  'p' => 'p',   
   'Q' => 'q',  'q' => 'q',   
   'R' => 'r',  'r' => 'r',   
   'S' => 's',  's' => 's',   
   'T' => 't',  't' => 't',   
   'U' => 'u',  'u' => 'u',   
   'V' => 'v',  'v' => 'v',   
   'W' => 'w',  'w' => 'w',   
   'X' => 'x',  'x' => 'x',   
   'Y' => 'y',  'y' => 'y',   
   'Z' => 'z',  'z' => 'z',   
  );
  return \%translitterationtable;
}

=head2 muse_naming_algo($string)

Algorithm to convert an url to its canonical form, which is used as
filename. It takes a string as argument and returns it converted.

URLs can be anything which is not separated by a dot or by a
slash. The maximum length is hardcoded to 95 (as files with more than
103 characters get truncated in a CD-ROM with jolet extension. Your
url can be as long as you want, but only the first 95 characters are
used to identify it. All the rest means nothing to us. If you are
running out of names, think about adding a numeric prefix or suffix.

Non-ascii characters are first translitterated. Everything
is then lower-cased. Spaces and underscores are replaced by
dashes. Trailing and leading dashes are removed and multiple dashes
are squeezed together.

The first two characters **must** be alphanumerical. If it's not so,
the name is stripped. of the first portion until the two character
are found.

=cut


# 2000 requests => 1.258 seconds
# new algo => 0.451 seconds

sub muse_naming_algo {
    my $dirtyline = shift;
    unless ((defined $dirtyline) and ($dirtyline ne "")) {
        return "";
    }
    my $fallback = $dirtyline;
    my @chars = split //, $dirtyline;
    my @cleaned;
    while (@chars) {
        last if $#cleaned > 93; # 93 is the index, so this means we have 94 + 1 = 95
        my $char = shift @chars;
        my $trslit = transliteration_table();
        if (exists $trslit->{$char}) {
            my $good = $trslit->{$char};
            # this check if we want to push empty strings --> no dashes
            if ($good ne "") {
                push @cleaned, $good;
            }
        }
        # over the second character we put dashes to replace dirty
        # characters. But only if we have already 2 of them in the stash
        else {
            if ((@cleaned) and
                ($cleaned[$#cleaned] ne "-")) {
                push @cleaned, "-";
            }
        }
    }
    # remove the trailing -
    while ($cleaned[$#cleaned] eq "-") {
        pop @cleaned;
    }
    my $clean = join ("", @cleaned);
    if ((length $clean) > 2) {
        return $clean;
    } else {
        return md5_hex(encode("UTF-8", $fallback))
    }
}

# 2000 requests for a long path with no hypens => 0.2 seconds. 0.16 for a short one

=head2 muse_get_full_path($filename);

Given the filename $filename, return an arrayref with the three
elements composing the path to the file local to the archive, taking
the first character and the next one after the first hyphen, or the
last one.

E.g. emma-goldman-living-my-life would return 

  [ 'e', 'eg', 'emma-goldman-living-my-life' ]

Or undef if the filename is dangerous.

=cut


sub muse_get_full_path {
  my $filename = shift;
  # path required, so don't be so sure about names.
  return undef unless $filename =~ m/^[a-z0-9][a-z0-9\-]*[a-z0-9]$/s;
  my @chars = split //, $filename;
  my @path;
  # given the above regexp, the first character is guaranteed to be a
  # letter or a number

  my %permitted_chars = (
                         'a' => '1',   '0' => '1',   
                         'b' => '1',   '1' => '1',   
                         'c' => '1',   '2' => '1',   
                         'd' => '1',   '3' => '1',   
                         'e' => '1',   '4' => '1',   
                         'f' => '1',   '5' => '1',   
                         'g' => '1',   '6' => '1',   
                         'h' => '1',   '7' => '1',   
                         'i' => '1',   '8' => '1',   
                         'j' => '1',   '9' => '1',   
                         'k' => '1',   		    
                         'l' => '1',   		    
                         'm' => '1',   		    
                         'n' => '1',   		    
                         'o' => '1',   		    
                         'p' => '1',   		    
                         'q' => '1',   		    
                         'r' => '1',   		    
                         's' => '1',   		    
                         't' => '1',   		    
                         'u' => '1',   		    
                         'v' => '1',   		    
                         'w' => '1',   		    
                         'x' => '1',   		    
                         'y' => '1',   		    
                         'z' => '1',
                        );

  die "we got hacked" unless $permitted_chars{$chars[0]};
  push @path, shift @chars; # and remove the first
  
  # then we look for the first hyphen.
  my $hyphen;
  foreach my $current (@chars) {
    if ($current eq "-") {
      $hyphen++;
      next;
    }
    next unless $hyphen;
    if ($permitted_chars{$current}) {
      push @path, $path[0] . $current;
      last;
    }
  }
  # ok, but what if we are still without a path because the page don't
  # have a hyphen?
  if ($#path == 1) {
    push @path, $filename;
    return \@path;
  }
  # simply we pop.
  while (@chars) {
    my $char = pop @chars;
    if ($permitted_chars{$char}) {
      push @path, $path[0] . $char;
      last;
    }
  }
  push @path, $filename;
  die "bad filename" if $#path < 2;
  return \@path;
}



sub _get_mtime {
  my $file = shift;
  my @stats = stat($file);
  my $mtime = $stats[9];
  return $mtime;
}




1;
