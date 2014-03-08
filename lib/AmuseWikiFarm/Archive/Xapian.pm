package AmuseWikiFarm::Archive::Xapian;

use strict;
use warnings;
use utf8;

use Moose;
use namespace::autoclean;

use Search::Xapian (':all');
use File::Spec;

has code => (is => 'ro',
             required => 1,
             isa => 'Str');

has locale => (
               is => 'ro',
               isa => 'Str',
               required => 0,
              );

has basedir => (
                is => 'ro',
                required => 0,
                isa => 'Str',
               );

has xapian_db => (is => 'ro',
                  isa => 'Object',
                  lazy => 1,
                  builder => '_build_xapian_db');

has xapian_indexer => (
                       is => 'ro',
                       isa => 'Object',
                       lazy => 1,
                       builder => '_build_xapian_indexer');


sub xapian_dir {
    my $self = shift;
    my @path;
    if (my $root = $self->basedir) {
        push @path, $root;
    }
    push @path, (xapian => $self->code);
    return File::Spec->catdir(@path);
}


sub _build_xapian_db {
    my $self = shift;
    my $db = $self->xapian_dir;
    unless (-d $db) {
        mkdir $db or die "Couldn't create $db $!";
    }
    return Search::Xapian::WritableDatabase->new($db, DB_CREATE_OR_OPEN);
}

sub _build_xapian_indexer {
    my $self = shift;
    my $indexer = Search::Xapian::TermGenerator->new();
    # set it by default with the locale stemmer, if available
    $indexer->set_stemmer($self->xapian_stemmer);
    return $indexer;
}

sub xapian_stemmer {
    my $self = shift;
    my $locale = $self->locale;
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


=head2 index_text($text_result_row)

The argument is a Title resultset. The text is indexed by Xapian in
the archive's database.

=cut


sub index_text {
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

sub search {
    my ($self, $query_string) = @_;
    my $database = Search::Xapian::Database->new($self->xapian_dir);

    # set up the query parser
    my $qp = Search::Xapian::QueryParser->new($database);

    # lot of room here for optimization and fun
    $qp->set_stemmer($self->xapian_stemmer);
    $qp->set_stemming_strategy(STEM_SOME);
    $qp->set_default_op(OP_AND);
    $qp->add_prefix(author => 'A');
    $qp->add_prefix(title => 'S');
    $qp->add_prefix(year => 'Y');
    $qp->add_prefix(date => 'Y');
    $qp->add_prefix(topic => 'K');
    $qp->add_prefix(source => 'XSOURCE');
    $qp->add_prefix(notes => 'XNOTES');
    $qp->add_boolean_prefix(uri => 'Q');

    my $query = $qp->parse_query($query_string,
                                 (FLAG_PHRASE   |
                                  FLAG_BOOLEAN  |
                                  FLAG_LOVEHATE |
                                  FLAG_WILDCARD ));

    my $enquire = $database->enquire($query);

    # paging
    my $mset = $enquire->get_mset(0, 50);
    my $msize = $mset->size;
    if ($msize == 0) {
        return;
    }

    my $totaldocs = $mset->get_matches_estimated();
    my @results;
    foreach my $m ($mset->items) {
        my $founddoc = {};
        $founddoc->{rank} = $m->get_rank + 1;
        $founddoc->{relevance} = $m->get_percent;
        $founddoc->{pagename} = $m->get_document->get_data;
        push @results, $founddoc;
    }
    return @results
}

__PACKAGE__->meta->make_immutable;

1;
