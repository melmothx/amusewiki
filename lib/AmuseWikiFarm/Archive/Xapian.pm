package AmuseWikiFarm::Archive::Xapian;

use strict;
use warnings;
use utf8;

use Moose;
use namespace::autoclean;

use Search::Xapian (':all');
use File::Spec;
use Data::Page;
use AmuseWikiFarm::Log::Contextual;
use Text::Unidecode ();
use Try::Tiny;

=head1 NAME

AmuseWikiFarm::Archive::Xapian - amusewiki Xapian model

=cut

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

has page => (
             is => 'rw',
             isa => 'Int',
             default => sub { return 10 },
            );

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
                    it => 'italian',
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

sub delete_text {
    my ($self, $text, $logger) = @_;
    if ($text) {
        $self->delete_text_by_uri($text->uri, $logger);
    }
}
sub delete_text_by_uri {
    my ($self, $uri, $logger) = @_;
    return unless $uri;
    eval {
        my $qterm = 'Q' . $uri;
        $self->xapian_db->delete_document_by_term($qterm);
        log_debug { "Removed $qterm from xapian db" };
    };
    if ($@) {
        log_debug { "Cannot remove Removed $uri from xapian db: $@" };
        $logger->("couldn't remove text: $@") if $logger;
    }
}

sub index_text {
    my ($self, $title, $logger) = @_;
    unless ($logger) {
        $logger = sub { warn join(" ", @_) };
    }
    # stolen from the example full-indexer.pl in Search::Xapian
    # get and create
    my $database = $self->xapian_db;
    my $indexer = $self->xapian_indexer;

    my $qterm = 'Q' . $title->uri;
    my $exit = 1;
    if (!$title->is_published) {
        $logger->("Deleting " . $title->uri . " from Xapian db\n");
        eval {
            $database->delete_document_by_term($qterm);
        };
    }
    else {
        $logger->("Updating " . $title->uri . " in Xapian db\n");
        try {
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
            # slurp by paragraph
            local $/ = "\n\n";
            while (my $line = <$fh>) {
                chomp $line;
                $line =~ s/^\#\w+//gm; # delete the directives
                $line =~ s/<.+?>//g; # delete the tags.
                if ($line =~ /\S/) {
                    $indexer->index_text($line);
                    # don't abort here. We index each line twice, once
                    # with the real string, once with the ascii
                    # representation.

                    # This technique is borrowed from elastic search,
                    # which suggests to index the text twice, once
                    # with the ascii representation, once with the
                    # real string.

                    # This way we have a match for both case.
                    try {
                        $indexer->index_text(Text::Unidecode::unidecode($line));
                        log_debug { Text::Unidecode::unidecode($line) };
                    } catch {
                        my $error = $_;
                        log_warn { "Cannot unidecode $line: $_" } ;
                    };
                }
            }
            close $fh;
            # Add or the replace the document to the database.
            $database->replace_document_by_term($qterm, $doc);
        } catch {
            my $error = $_;
            log_warn { "$error indexing $qterm" } ;
            $exit = 0;
        };
    }
    return $exit;
}

=head2 search($query_string, $page);

Run a query against the Xapian database. Return the number of matches
and a list of matches, each being an hashref with the following keys:

=cut

sub search {
    my ($self, $query_string, $page) = @_;
    my $pager = Data::Page->new;
    return $pager unless $query_string;

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
    my $pagesize = $self->page;
    # be sure to have a number
    unless ($page and $page =~ m/\A[1-9][0-9]*\z/) {
        $page = 1;
    }
    my $start = ($page - 1) * $pagesize;
    my $mset = $enquire->get_mset($start, $pagesize, $pagesize);
    $pager->total_entries($mset->get_matches_estimated);
    $pager->entries_per_page($pagesize);
    $pager->current_page($page);
    my @results;
    foreach my $m ($mset->items) {
        my $founddoc = {};
        $founddoc->{rank} = $m->get_rank + 1;
        $founddoc->{relevance} = $m->get_percent;
        $founddoc->{pagename} = $m->get_document->get_data;
        push @results, $founddoc;
    }
    return $pager, @results;
}

=over 4

=item rank

=item relevance

=item pagename

=back

=cut





__PACKAGE__->meta->make_immutable;

1;
