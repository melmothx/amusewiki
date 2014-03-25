package AmuseWikiFarm::Archive::Special;

use strict;
use warnings;
use utf8;

use Moose;
use namespace::autoclean;

use File::Spec;
use File::Basename qw/basename/;
use Cwd;
use Data::Dumper;
use Text::Amuse;
use Date::Parse;
use File::Copy;
use DateTime;
use AmuseWikiFarm::Utils::Amuse qw/muse_filename_is_valid/;

=head2 site_schema

Given that the special pages belongs to a site, the constructor wants
the site result. From there we can track back everything else we need.

=cut

has site_schema => (is => 'ro',
                    required => 1,
                    isa => 'Object');

has basedir => (is => 'ro',
                required => 1,
                default => sub { getcwd },
                isa => 'Str');

has error => (is => 'rw',
              default => sub { 'No error found' },
              isa => 'Str');

sub find_page {
    my ($self, $uri) = @_;
    my $page = $self->site_schema->pages->search({
                                                  uri => $uri,
                                                  # status => 'published'
                                                 })->single;
    return $page;
}

sub special_dir {
    return 'specials';
}

sub muse_dir {
    my $self = shift;
    return File::Spec->catdir($self->basedir, $self->special_dir,
                              $self->site_schema->id);
}

sub path_to_muse {
    my ($self, $uri) = @_;
    return unless muse_filename_is_valid($uri);
    my $target = File::Spec->catfile($self->muse_dir, $uri . '.muse');
    return $self->get_absolute_path($target);
}

sub edit {
    my ($self, $uri, $params) = @_;
    print Dumper($params);
    my $target = $self->path_to_muse($uri);
    unless ($target) {
        $self->error('Invalid path!');
        return;
    }
    unless ($params->{body} && $params->{body} =~ m/\w/) {
        $self->error('Empty text!');
        return;
    }
    unless ($params->{body} =~ m/^#title .+/s) {
        $self->error('No title found as first line!');
        return;
    }
    # new text? make a copy
    if (-f $target) {
        my $backup = DateTime->now->iso8601;
        $backup =~ s/\W/-/g;
        move($target, $target . '~' . $backup)
          or die "Couldn't move $target into $backup! $!";
    }

    # FIXING
    # remove carriage returns
    $params->{body} =~ s/\r//gs;
    # remove tabs
    $params->{body} =~ s/\t/    /gs;
    # add two new line as a good measure
    $params->{body} .= "\n\n";

    open (my $fh, '>:encoding(utf-8)', $target) or die $!;
    print $fh $params->{body};
    close $fh;
    # and index the file
    return $self->import_file($target);
}

sub import_file {
    my ($self, $path) = @_;
    die "$path is not a file" unless -f $path;
    print "Working on $path\n";
    my $muse = Text::Amuse->new(file => $path);
    my $body =  $muse->as_html;
    # check if the title is present
    my $title = $muse->header_as_html->{title};
    unless ($title and $title =~ m/\w/) {
        $self->error("No title found!, skipping");
        return;
    }

    # strip the tags from the title
    $title =~ s/<.*?>//g;
    unless ($title =~ m/\w/) {
        warn "No title found in $path! after stripping, skipping\n";
        return;
    }

    # set the dates
    my $pubdate = str2time($muse->header_as_html->{pubdate}) || time();
    # eventually check if it's in the future, but not now.
    my $pubdt = DateTime->from_epoch(epoch => $pubdate);
    my $now = DateTime->now;
    my $uri = basename($path, '.muse');
    $path = $self->get_absolute_path($path);
    my $text = $self->site_schema->pages->update_or_create({
                                                            uri   => $uri,
                                                            title => $title,
                                                            html_body => $body,
                                                            created => $now,
                                                            updated => $now,
                                                            pubdate => $pubdt,
                                                            f_path => $path,
                                                           });
    print "Done $path\n";
    return $text;
}

sub get_absolute_path {
    my ($self, $file) = @_;
    die "Wrong usage" unless $file;
    unless (File::Spec->file_name_is_absolute($file)) {
        $file = File::Spec->rel2abs($file);
    }
    return $file;
}

__PACKAGE__->meta->make_immutable;

1;
