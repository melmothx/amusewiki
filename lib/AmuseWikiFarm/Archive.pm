package AmuseWikiFarm::Archive;

use strict;
use warnings;
use utf8;

use Moose;
use namespace::autoclean;

use Search::Xapian (':all');
use AmuseWikiFarm::Utils::Amuse qw/muse_file_info/;

has xapian => (is => 'ro',
               required => 0,
               isa => 'Str');

has repo   => (is => 'ro',
               required => 1,
               isa => 'Str');

has fields => (is => 'ro',
               isa => 'HashRef[Str]',
               lazy => 1,
               builder => '_build_fields');

has xapian_db => (is => 'ro',
                  isa => 'Object',
                  lazy => 1,
                  builder => '_build_xapian_db');

has xapian_indexer => (
                       is => 'ro',
                       isa => 'Object',
                       lazy => 1,
                       builder => '_build_xapian_indexer');

has code => (is => 'ro',
             required => 1,
             isa => 'Str');

has locale => (is => 'ro',
               required => 0,
               isa => 'Str');

has dbic   => (is => 'ro',
               isa => 'Object');

sub _build_xapian_db {
    my $self = shift;
    my $db = $self->xapian;
    unless (-d $db) {
        mkdir $db or die "Couldn't create $db $!";
    }
    return Search::Xapian::WritableDatabase->new($db, DB_CREATE_OR_OPEN);
}

sub _build_xapian_indexer {
    my $self = shift;
    my $indexer = Search::Xapian::TermGenerator->new();
    # set it by default with the locale stemmer, if available
    $indexer->set_stemmer($self->xapian_stemmer($self->locale));
    return $indexer;
}

sub _build_fields {
    my $self = shift;
    warn "Building fields\n";
    my %fields = map { $_ => 1 }
      $self->dbic->resultset('Title')->result_source->columns;
    return \%fields;
}

sub xapian_stemmer {
    my ($self, $locale) = @_;
    # from http://xapian.org/docs/apidoc/html/classXapian_1_1Stem.html
    my %stemmers = (
                    da => 'danish',
                    nl => 'dutch',
                    en => 'english',
                    fi => 'finnish',
                    fr => 'french',
                    de => 'german',
                    hu => 'hungarian',
                    it => 'italina',
                    no => 'norwegian',
                    pt => 'portuguese',
                    ro => 'romanian',
                    ru => 'russian',
                    es => 'spanish',
                    sv => 'swedish',
                    tr => 'turkish',
                   );
    if ($locale && $stemmers{$locale}) {
        return Search::Xapian::Stem->new($stemmers{$locale});
    }
    else {
        return Search::Xapian::Stem->new('none');
    }
}

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
    my %insertion;
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
    if ($parsed_cats && @$parsed_cats) {
        # here we can die if there are duplicated uris
        $title->set_categories($parsed_cats);
    }

    # TODO maybe the categories should be cleaned if there are none?

    return $file unless $self->xapian;
    # print $title->topic_list, ' ', $title->author_list, "\n";
    # XAPIAN INDEXING

    $self->xapian_index_text($title);
    return $file;
}


sub xapian_index_text {
    my ($self, $title) = @_;
    # stolen from the example full-indexer.pl in Search::Xapian
    # get and create
    my $database = $self->xapian_db;
    my $indexer = $self->xapian_indexer;

    my $qterm = 'Q' . $title->uri;

    if ($title->deleted) {
        print "Deleting " . $title->uri . " from Xapian db\n";
        eval {
            $database->delete_document_by_term($qterm);
        };
    }
    else {
        print "Updating " . $title->uri . " in Xapian db\n";
        eval {
            my $doc = Search::Xapian::Document->new();
            $indexer->set_document($doc);

            # Set the document data to the uri so we can show it for matches.
            $doc->set_data($title->uri);

            # Unique ID.
            $doc->add_term($qterm);

            # To allow sorting by author.
            # $doc->add_value($SLOT_AUTHOR, $author);

            # To allow sorting by title..
            # $doc->add_value($SLOT_TITLE, $doc_name);

            # Index the author to allow fielded free-text searching.
            if (my $author = $title->author) {
                $indexer->index_text($author, 1, 'A');
            }

            if (my $author_list = $title->author_list) {
                # with lesser weight, index the list
                $indexer->index_text($author_list, 2, 'A');
            }

            # Index the title and subtitle to allow fielded free-text searching.
            $indexer->index_text($title->title, 1, 'S');

            if (my $subtitle = $title->subtitle) {
                $indexer->index_text($subtitle, 2, 'S');
            }

            # To allow date range searching and sorting by date.
            if ($title->date and $title->date =~ /(\d{4})/) {
                $indexer->index_text($1, 1, 'Y');
                # $doc->add_value($SLOT_DATE, "$1$2$3");
            }

            if (my $topic_list = $title->topic_list) {
                $indexer->index_text($topic_list, 1, 'K');
            }
            if (my $source = $title->source) {
                $indexer->index_text($source, 1, 'XSOURCE');
            }
            if (my $notes = $title->notes) {
                $indexer->index_text($notes, 1, 'XNOTES');
            }

            # Increase the term position so that phrases can't straddle the
            # doc_name and keywords.
            $indexer->increase_termpos();

            my $filepath = $title->f_full_path_name;
            open (my $fh, '<:encoding(UTF-8)', $filepath)
              or die "Couldn't open $filepath: $!";
            while (my $line = <$fh>) {
                $line =~ s/^\#\w+//g; # delete the directives
                $line =~ s/<.+?>//g; # delete the tags.
                $indexer->index_text($line);
            }
            close $fh;

            # Add or the replace the document to the database.
            $database->replace_document_by_term($qterm, $doc);
        };
    }
    warn $@ if $@;
    $@ ? return : return 1;
}



__PACKAGE__->meta->make_immutable;

1;
