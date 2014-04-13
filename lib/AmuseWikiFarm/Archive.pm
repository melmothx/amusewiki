package AmuseWikiFarm::Archive;

use strict;
use warnings;
use utf8;

use Moose;
use namespace::autoclean;

use Search::Xapian (':all');
use AmuseWikiFarm::Utils::Amuse qw/muse_file_info/;
use Unicode::Collate::Locale;
use File::Spec;
use File::Copy;
use AmuseWikiFarm::Archive::Xapian;
use Text::Amuse::Compile;
use Git::Wrapper;

has code => (is => 'ro',
             required => 1,
             isa => 'Str');

has dbic => (is => 'ro',
             required => 1,
             isa => 'Object');

has basedir => (is => 'ro',
                required => 0,
                isa => 'Str');

has xapian => (is => 'ro',
               required => 0,
               isa => 'Object',
               lazy => 1,
               builder => '_build_xapian_object',
              );

sub _build_xapian_object {
    my $self = shift;
    return AmuseWikiFarm::Archive::Xapian->new(
                                               code => $self->code,
                                               basedir => $self->basedir || '',
                                               locale => $self->site->locale,
                                              );
}

has fields => (is => 'ro',
               isa => 'HashRef[Str]',
               lazy => 1,
               builder => '_build_fields');

sub _build_fields {
    my $self = shift;
    my %fields = map { $_ => 1 }
      $self->dbic->resultset('Title')->result_source->columns;
    return \%fields;
}

has site_exists => (is => 'ro',
                    required => 1,
                    isa => 'Str',
                    lazy => 1,
                    builder => '_build_site_exists');

sub _build_site_exists {
    my $self = shift;
    my $site = $self->site;
    $site ? return 1 : return 0;
    
}

sub repo {
    my $self = shift;
    my @path;
    if (my $root = $self->basedir) {
        push @path, $root;
    }
    push @path, (repo => $self->code);
    my $dir = File::Spec->catdir(@path);
    die "Fatal, no repo found!" unless -d $dir;
    return $dir;
}

sub site {
    my $self = shift;
    return $self->dbic->resultset('Site')->find($self->code);
}


=head2 publish_revision($revision)

Receive a revision id as first argument and publish it.

TODO this method probably belongs to Result::Revision

Procedure:

=over 4

=item carefully move it in the target directory

=item if in a git directory, add it to the git and commit

=item compile the file and report errors, if any

=item call index_file on the muse and the attachments

=item call collation_index

=back

=cut

sub publish_revision {
    # TODO add $force argument if the revisions can't me merged cleanly
    my ($self, $id) = @_;
    die "Wrong usage" unless defined $id;

    my $rev = $self->site->revisions->find($id);
    # let it die if rev is undef.
    my %files = $rev->destination_paths;

    # catch the muse files and its attachments, and validate it.
    my $muse;
    my @attachments;
    foreach my $src (keys %files) {
        my $target = $files{$src};
        if ($target =~ m/\.muse$/) {
            die "Multiple muse files found in " . $rev->id if $muse;
            $muse = $target;
        }
        else {
            push @attachments, $target;
        }
    }
    # first process the muse file
    die "muse file not found in " . $rev->id unless $muse;

    my $git;
    if ($rev->site->repo_is_under_git) {
        $git = Git::Wrapper->new($rev->site->repo_root);
    }
    my $revid = $rev->id;

    if ($git and -f $rev->original_html) {
        die "Original html found, but target exists" if -f $muse;
        copy ($rev->original_html, $muse) or die $!;
        # TODO see if the starting file needs to be saved as well
        # it contains a non-filtered copy
        $git->add($muse);
        # add the author
        $git->commit({ message => "Imported HTML revision no.$revid"});
    }

    foreach my $k (keys %files) {
        my $dest = $files{$k};
        if ($dest ne $muse) {
            # this shouldn't happen
            die "Attachment already exists" if -f $dest;
        }
        copy($k, $dest) or die "Couldn't copy $k to $dest $!";

        if ($git) {
            $git->add($dest);
        }
    }

    if ($git) {
        if ($git->status->is_dirty) {
            # TODO add message and author
            $git->commit({ message => "Published revision $revid" });
        }
        else {
            warn "Revision $revid published, but no changes in the git. Why?";
        }
    }

    my $compiler = Text::Amuse::Compile->new($rev->site->compile_options);
    $compiler->compile($muse);
    foreach my $f (values %files) {
        $self->index_file($f);
    }
    $self->collation_index;
    $rev->status('published');
    $rev->update; # or even delete it
    return $rev->muse_uri;
}


=head2 index_file($file)

Add the file to the DB and Xapian databases, first parsing it with
C<muse_info_file> from L<AmuseWikiFarm::Utils::Amuse>.

=cut

sub index_file {
    my ($self, $file) = @_;
    unless ($file && -f $file) {
        $file ||= '<empty>';
        warn "File $file does not exist";
        return;
    }

    my $details = muse_file_info($file, $self->code);
    # unparsable
    return unless $details;

    if ($details->{f_suffix} ne '.muse') {
        warn "Inserting data for attachment $file\n";
        $self->dbic->resultset('Attachment')->update_or_create($details);
        return $file;
    }

    # ready to store into titles?
    # by default text are published, unless the file info returns something else
    # and if it's an update we have to reset it.
    my %insertion = (deleted => '');
    # lower case the keys
    foreach my $col (keys %$details) {
        my $db_col = lc($col);
        if (exists $self->fields->{$db_col}) {
            $insertion{$db_col} = delete $details->{$col};
        }
    }

    my $parsed_cats = delete $details->{parsed_categories};
    if (%$details) {
        warn "Unhandle directive in $file: " . join(", ", %$details) . "\n";
    }
    print "Inserting data for $file\n";
    # TODO: see if we have to update the insertion

    my $title = $self->dbic->resultset('Title')->update_or_create(\%insertion);

    # pick the old categories.
    my @old_cats_ids;
    foreach my $old_cat ($title->categories) {
        push @old_cats_ids, $old_cat->id;
    }

    if ($title->is_deleted) {
        $title->status('deleted');
    }
    elsif ($title->is_deferred) {
        $title->status('deferred');
    }
    elsif ($title->is_published) {
        $title->status('published');
    }
    $title->update if $title->is_changed;

    if ($title->is_published && $parsed_cats && @$parsed_cats) {
        # here we can die if there are duplicated uris
        $title->set_categories($parsed_cats);
    }
    else {
        # purge the categories if there is none.
        $title->set_categories([]);
    }

    foreach my $cat ($title->categories) {
        $cat->title_count_update;
    }

    foreach my $cat_id (@old_cats_ids) {
        my $cat = $self->dbic->resultset('Category')->find($cat_id);
        $cat->title_count_update;
    }

    return $file unless $self->xapian;
    # print $title->topic_list, ' ', $title->author_list, "\n";
    # XAPIAN INDEXING

    $self->xapian->index_text($title);
    return $file;
}


=head2 collation_index

Update the C<sorting_pos> field of each text and category based on the
collation for the current locale.

Collation on the fly would have been too slow, or would depend on the
(possibly crappy) collation of the database engine, if any.

=cut

sub collation_index {
    my $self = shift;
    my $site = $self->site;
    my $collator = Unicode::Collate::Locale->new(locale => $site->locale);

    my @texts = sort {
        # warn $a->id . ' <=>  ' . $b->id;
        $collator->cmp($a->list_title, $b->list_title)
    } $site->titles;

    my $i = 1;
    foreach my $t (@texts) {
        $t->sorting_pos($i++);
        $t->update if $t->is_changed;
    }

    # and then sort the categories
    my @categories = sort {
        # warn $a->id . ' <=> ' . $b->id;
        $collator->cmp($a->name, $b->name)
    } $site->categories;

    $i = 1;
    foreach my $cat (@categories) {
        $cat->sorting_pos($i++);
        $cat->update if $cat->is_changed;
    }

}

__PACKAGE__->meta->make_immutable;

1;
