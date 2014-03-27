package AmuseWikiFarm::Archive::Edit;

use strict;
use warnings;
use utf8;

use Moose;
use namespace::autoclean;

use File::Spec;
use File::Basename qw/basename/;
use File::Copy;
use Cwd;
use Data::Dumper;
use Date::Parse;
use DateTime;

use Text::Amuse;
use Text::Amuse::Preprocessor::HTML qw/html_to_muse/;
use AmuseWikiFarm::Utils::Amuse qw/muse_naming_algo/;

=head1 SYNOPSIS

This class must B<not> be reusued. Create in one request and throw it
away.

=cut

has site_schema => (is => 'ro',
                    required => 1,
                    isa => 'Object');

has basedir => (is => 'ro',
                required => 1,
                default => sub { getcwd },
                isa => 'Str');

has error => (is => 'rw',
              isa => 'Str');

has redirect => (is => 'rw',
                 isa => 'Str');

sub staging_dirname {
    return 'staging';
}

sub staging_dir {
    my $self = shift;
    return File::Spec->catdir($self->basedir, $self->staging_dirname);
}

sub create_new {
    my ($self, $params) = @_;

    # assert that the directory where to put the files exists
    my $staging_dir = $self->staging_dir;
    unless (-d $staging_dir) {
        mkdir $self->staging_dir or die "Couldn't create $staging_dir $!";
    }

    # URI generation
    my $author = $params->{author} || "";
    my $title  = $params->{title}  || "";
    my $uri;
    if ($params->{uri}) {
        $uri = muse_naming_algo($params->{uri});
        # replace the params with our clean form
    }
    elsif ($title) {
        $uri = muse_naming_algo("$author $title");
    }
    unless ($uri) {
        $self->error("Couldn't generate the uri!");
        return;
    }
    # and store it in the params
    $params->{uri} = $uri;


    # check if the uri already exists. If so, throw an error and set
    # the redirection.

    my $exists = $self->site_schema->titles->find({ uri => $uri });
    if ($exists) {
        $self->error("Such an uri already exists");
        $self->redirect($exists->uri);
        return;
    }
    else {
        return $self->import_text_from_html_params($params);
    }
}

sub import_text_from_html_params {
    my ($self, $params) = @_;
    my $uri = $params->{uri};
    die "uri not set!" unless $uri;

    # the first thing we do is to assing a path and create a revision in the db
    my $pubdate = str2time($params->{pubdate}) || time();
    my $pubdt = DateTime->from_epoch(epoch => $pubdate);
    $params->{pubdate} = $pubdt->iso8601;

    # documented in Result::Title
    my $bogus = {
                 uri => $uri,
                 pubdate => $pubdate,
                 f_suffix => '.muse',
                 status => 'editing',
                };

    foreach my $f (qw/f_path f_archive_rel_path f_timestamp
                      f_full_path_name f_name/) {
        $bogus->{$f} = '';
    }

    my $title = $self->site_schema->titles->create($bogus);

    
    # where to store the text. But we need to know which id we have in
    # advance, so first set f_path to the empty string.

    my $revision = $self->create_revision_for_title($title);

    my $file = $revision->f_full_path_name;
    die "full path was not set!" unless $file;

    # save a copy of the html request
    my $html_copy = File::Spec->catfile($revision->original_html);
    if (defined $params->{textbody}) {
        open (my $fhh, '>:encoding(utf-8)', $html_copy)
          or die "Couldn't open $html_copy $!";
        print $fhh $params->{textbody};
        close $fhh or die $!;
    }

    # populate the file with the parameters
    open (my $fh, '>:encoding(utf-8)', $file) or die "Couldn't open $file $!";
    # TODO add support for uid and cat (ATR)
    foreach my $directive (qw/title subtitle author LISTtitle SORTauthors
                              SORTtopics date
                              source lang pubdate/) {

        $self->_add_directive($fh, $directive, $params->{$directive});
    }
    # add the notes
    $self->_add_directive($fh, notes => html_to_muse($params->{notes}));
                          
    # separator
    print $fh "\n";

    my $body = html_to_muse($params->{textbody});
    if (defined $body) {
        print $fh $body;
    }
    print $fh "\n\n";
    close $fh or die $!;
    return $revision;
}

sub _add_directive {
    my ($self, $fh, $directive, $text) = @_;
    die unless $fh && $directive;
    return unless defined $text;
    # usual washing
    $text =~ s/\r*\n/ /gs; # it's a directive, no \n
    # leading and trailing spaces
    $text =~ s/^\s*//s;
    $text =~ s/\s+$//s;
    $text =~ s/  +/ /gs; # pack the whitespaces
    return unless length($text);
    print $fh '#' . $directive . ' ' . $text . "\n";
}

sub create_revision_for_title {
    my ($self, $title ) = @_;
    my $revision = $title->revisions->create({
                                              # help dbic to cope with this
                                              site_id => $title->site->id,
                                              updated => DateTime->now,
                                             });
    my $uri = $revision->title->uri;
    die "Couldn't find uri for belonging title!" unless $uri;
    
    # the root
    my $target_dir = File::Spec->catdir($self->staging_dir, $revision->id);
    if (-d $target_dir) {
        # mm, some db backend is reusing the ids, so clean it up
        opendir(my $dh, $target_dir) or die "Can't open dir $target_dir $!";
        my @cleanup = grep {
            -f File::Spec->catfile($target_dir, $_)
        } readdir($dh);
        closedir $dh;
        foreach my $clean (@cleanup) {
            warn "Removing $clean in $target_dir";
            unlink File::Spec->catfile($target_dir, $clean) or warn $!;
        }
    }
    else {
        mkdir $target_dir or  die "Couldn't create $target_dir $!";
    }
    my $fullpath = File::Spec->catfile($target_dir, $uri . '.muse');
    $revision->f_full_path_name($fullpath);
    $revision->update;
    return $revision;
}

=head2 new_revision($text)

The argument is the Title result row. Create a new revision for it.

=head2 new_revision_from_uri("my-text");

Same as above, but passing an uri.

=cut

sub new_revision_from_uri {
    my ($self, $uri) = @_;
    my $text = $self->site_schema->titles->find({ uri => $uri });
    return $self->new_revision($text);
}

sub new_revision {
    my ($self, $text) = @_;
    return unless $text;
    my $revision = $self->create_revision_for_title($text);
    # and copy the file in the new dir
    copy($text->f_full_path_name, $revision->f_full_path_name);
    # TODO copy the file as orig.muse, so we can store the full history
    return $revision;
}

__PACKAGE__->meta->make_immutable;

1;
