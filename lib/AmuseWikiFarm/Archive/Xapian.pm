package AmuseWikiFarm::Archive::Xapian;

use strict;
use warnings;
use utf8;

use Moo;
use Types::Standard qw/Int Maybe Object HashRef ArrayRef InstanceOf Str Bool/;

use Search::Xapian (':all');
use File::Spec;
use Data::Page;
use AmuseWikiFarm::Log::Contextual;
use Text::Unidecode ();
use Try::Tiny;
use Path::Tiny ();
use JSON::MaybeXS;
use AmuseWikiFarm::Archive::Xapian::Result;
use AmuseWikiFarm::Archive::Xapian::Result::Text;
use namespace::clean;

use constant {
              AMW_XAPIAN_VERSION => 2,
              SLOT_AUTHOR => 0,
              SLOT_TOPIC => 1,
              SLOT_PUBDATE => 2,
              SLOT_QUALIFICATION => 3,
              SLOT_PAGES => 4,
              SLOT_DATE => 5,
              SLOT_TITLE => 6,
              SLOT_PUBDATE_FULL  => 7,
              SLOT_PAGES_FULL  => 8,
              SLOT_LANG => 9,
              SLOT_HOSTNAME => 10,
              SORT_ASC => 0,
              SORT_DESC => 1,
             };


my %SLOTS = (
             author => {
                        slot => SLOT_AUTHOR,
                        prefix => 'XA',
                        singlesite => 1,
                       },
             topic => {
                       slot => SLOT_TOPIC,
                       prefix => 'XK',
                       singlesite => 1,
                      },
             pubdate => {
                         slot => SLOT_PUBDATE,
                         prefix => 'XP',
                         singlesite => 0,
                        },
             qualification => {
                               slot => SLOT_QUALIFICATION,
                               prefix => 'XQ',
                               singlesite => 0,
                              },
             pages => {
                       slot => SLOT_PAGES,
                       prefix => 'XL',
                       singlesite => 0,
                      },
             date => {
                      slot => SLOT_DATE,
                      prefix => 'XD',
                      singlesite => 0,
                     },
             language => {
                          slot => SLOT_LANG,
                          prefix => 'L',
                          singlesite => 0,
                         },
             hostname => {
                          slot => SLOT_HOSTNAME,
                          prefix => 'H',
                          singlesite => 0,
                         },
            );

sub sortings {
    my %out = (
               pubdate => SLOT_PUBDATE_FULL,
               pages => SLOT_PAGES_FULL,
               title => SLOT_TITLE,
              );
    return %out;
}


=head1 NAME

AmuseWikiFarm::Archive::Xapian - amusewiki Xapian model

=cut

has code => (is => 'ro',
             required => 0,
             isa => Str);

has multisite => (is => 'ro',
                  isa => Bool,
                  default => sub { 0 });

has stub_database => (is => 'ro',
                      isa => Str);

has locale => (
               is => 'ro',
               isa => Str,
               required => 0,
              );

has stem_search => (
                    is => 'ro',
                    isa => Bool,
                    default => sub { return 1 },
                   );

has index_deferred => (is => 'ro',
                       isa => Bool,
                       default => sub { return 0 });

has basedir => (
                is => 'ro',
                required => 0,
                isa => Str,
               );

has page => (
             is => 'rw',
             isa => Int,
             default => sub { return 10 },
            );

has auxiliary => (
                  is => 'ro',
                  isa => Bool,
                  default => sub { 0 },
                 );

has temporary_suffix => (is => 'ro',
                         isa => Str,
                         default => sub { '~' . time() }
                        );

sub _path_tokens {
    my $self = shift;
    my @path;
    if (my $root = $self->basedir) {
        push @path, $root;
    }
    push @path, 'xapian';
    my $code = $self->code or die "site code not provided, cannot guess the path";
    if ($self->auxiliary) {
        $code .= $self->temporary_suffix;
    }
    push @path, $code;
    return @path;
}

sub xapian_dir {
    my $self = shift;
    if (my $stub = $self->stub_database) {
        return $stub;
    }
    else {
        return File::Spec->catdir($self->_path_tokens);
    }
}

sub xapian_backup_dir {
    my $self = shift;
    my @path = $self->_path_tokens;
    $path[-1] .= '~backup';
    return Path::Tiny::path(@path);
}

sub specification_file {
    my $self = shift;
    my @path = $self->_path_tokens;
    $path[-1] .= '.json';
    return Path::Tiny::path(@path);
}

sub write_specification_file {
    my $self = shift;
    $self->specification_file->spew(encode_json({ version => AMW_XAPIAN_VERSION }));
}

sub read_specification_file {
    my $self = shift;
    my $spec_file = $self->specification_file;
    if ($spec_file->exists) {
        my $spec = $spec_file->slurp;
        return decode_json($spec);
    }
    return undef;
}


sub xapian_db {
    my $self = shift;
    my $db = $self->xapian_dir;
    unless (-d $db) {
        mkdir $db or die "Couldn't create $db $!";
    }
    return Search::Xapian::WritableDatabase->new($db, DB_CREATE_OR_OPEN);
}

sub xapian_stemmer {
    my ($self, $locale) = @_;
    $locale ||= $self->locale;
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
        log_debug { "Creating stemmer with $stemmers{$locale}" };
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
    # exclude specials
    return unless $title->is_regular;
    unless ($logger) {
        $logger = sub { warn join(" ", @_) };
    }
    # stolen from the example full-indexer.pl in Search::Xapian
    # get and create
    my $database = $self->xapian_db;
    my $indexer = Search::Xapian::TermGenerator->new();
    $indexer->set_database($database);
    $indexer->set_flags(FLAG_SPELLING_CORRECTION);
    # indexing with the correct stemmer is the right thing to do. No
    # point in stemming with the wrong locale. if i understand
    # correctly, the unstemmed version is indexed anyway.

    $indexer->set_stemmer($self->xapian_stemmer($title->lang));

    my $qterm = 'Q' . $title->uri;
    my $exit = 1;
    if ($title and ($title->is_published or ($self->index_deferred && $title->can_be_indexed))) {
        $logger->("Updating " . $title->uri . " in Xapian db\n");
        try {
            my $doc = Search::Xapian::Document->new();
            $indexer->set_document($doc);

            # Set the document data to the uri so we can show it for matches.
            # this is treated as blob.
            my $abstract = AmuseWikiFarm::Archive::Xapian::Result::Text->new($title);
            $doc->set_data(encode_json($abstract->clone_args));

            # Unique ID.
            $doc->add_term($qterm);

            # Index the author to allow fielded free-text searching.
            if (my $author = $title->author) {
                $indexer->index_text($author, 1, 'A');
            }
            # Index the title and subtitle to allow fielded free-text searching.
            $indexer->index_text($title->title, 1, 'S');

            if (my $subtitle = $title->subtitle) {
                $indexer->index_text($subtitle, 2, 'S');
            }

            my %cats = (
                        author => { key => 'A', index => 2, rs => 'authors_only' },
                        topic =>  { key => 'K', index => 1, rs => 'topics_only' },
                       );
            foreach my $cat (keys %cats) {
                my @list;
                my $prefix = $cats{$cat}{key};
                my $rs = $cats{$cat}{rs};
                my $index = $cats{$cat}{index};
                foreach my $item ($title->categories->$rs->all) {
                    push @list, $item->full_uri;
                    $doc->add_boolean_term($SLOTS{$cat}{prefix} . $item->full_uri);
                    $indexer->index_text($item->name, $index, $prefix);
                }
                $doc->add_value($SLOTS{$cat}{slot}, encode_json(\@list));
            }

            if (my $decade = $title->date_decade) {
                $doc->add_value($SLOTS{date}{slot}, $decade);
                $doc->add_boolean_term($SLOTS{date}{prefix} . $decade);
                $doc->add_boolean_term('Y'  . $title->date_year);
            }

            my $pub_date = $title->pubdate;
            $doc->add_value($SLOTS{pubdate}{slot}, $pub_date->epoch);
            $doc->add_value(SLOT_PUBDATE_FULL, Search::Xapian::sortable_serialise($title->pubdate->epoch));
            $doc->add_boolean_term($SLOTS{pubdate}{prefix} .  $pub_date->year);

            $doc->add_value($SLOTS{pages}{slot}, $title->page_range);
            $doc->add_boolean_term($SLOTS{pages}{prefix} .  $title->page_range);

            if (my $qual = $title->text_qualification) {
                $doc->add_value($SLOTS{qualification}{slot}, $qual);
                $doc->add_boolean_term($SLOTS{qualification}{prefix} . $qual);
            }

            if (my $lang = $title->lang) {
                $doc->add_value($SLOTS{language}{slot}, $lang);
                $doc->add_boolean_term($SLOTS{language}{prefix} . $lang);
            }
            if (my $site = $title->site) {
                if (my $canonical = $site->canonical) {
                    $doc->add_value($SLOTS{hostname}{slot}, $canonical);
                    $doc->add_boolean_term($SLOTS{hostname}{prefix} . $canonical);
                }
            }

            # for sorting purposes
            $doc->add_value(SLOT_TITLE, Text::Unidecode::unidecode($title->list_title || $title->title));
            $doc->add_value(SLOT_PAGES_FULL, Search::Xapian::sortable_serialise($title->pages_estimated));

            if (my $source = $title->source) {
                $indexer->index_text($source, 1, 'XSOURCE');
            }
            if (my $notes = $title->notes) {
                $indexer->index_text($notes, 1, 'XNOTES');
            }

            # Increase the term position so that phrases can't straddle the
            # doc_name and keywords.
            $indexer->increase_termpos();

            foreach my $method (qw/title subtitle author teaser source notes/) {
                if (my $thing = $title->$method) {
                    $self->_index_html($indexer, $thing);
                }
            }
            my $file = Path::Tiny::path($title->filepath_for_ext('bare.html'));
            $self->_index_html($indexer, $file->slurp_utf8);
            $database->replace_document_by_term($qterm, $doc);
        } catch {
            my $error = $_;
            log_warn { "$error indexing $qterm" } ;
            $exit = 0;
        };
    }
    else {
        $logger->("Deleting " . $title->uri . " from Xapian db\n");
        try {
            $database->delete_document_by_term($qterm);
        } catch {
            my $error = $_;
            log_warn { "$error deleting $qterm" } ;
            $exit = 0;
        }
    }
    return $exit;
}

=head2 search($query_string, $page, $locale);

Run a query against the Xapian database. Return the number of matches
and a list of matches, each being an hashref with the following keys:

=over 4

=item rank

=item relevance

=item pagename

=back

The stemming of the search term is activate only if the third argument
is passed and stem_search is true and if the locale passed matches the
site locale.

=cut

sub search {
    my ($self, $query_string, $page, $locale) = @_;
    my $res = $self->faceted_search(
                                    locale => $locale,
                                    facets => 0,
                                    filters => 1,
                                    page => $page,
                                    query => $query_string,
                                   );
    return $res->pager, @{$res->matches};
}

sub faceted_search {
    my ($self, %args) = @_;
    my $res = try {
        $self->_do_faceted_search(%args);
    } catch {
        my $err = $_;
        log_error { "$err calling faceted_search $args{query}" };
        AmuseWikiFarm::Archive::Xapian::Result->new(error => "$err");
    };
    return $res;
}

sub _do_faceted_search {
    my ($self, %args) = @_;
    foreach my $default (qw/facets filters/) {
        $args{$default} = 1 unless exists $args{$default};
    }
    my $database = Search::Xapian::Database->new($self->xapian_dir);
    my $qp = Search::Xapian::QueryParser->new($database);

    # locale + stemming
    my $locale = $args{locale};
    # if the locale passed doesn't match with the main language, don't
    # use the stemming. However, this will probably prevent to find
    # documents in other languages which was stemmed differently.
    if ($locale and $self->stem_search and $locale eq $self->locale ) {
        log_debug { "Using $locale for stemming" };
    }
    else {
        $locale = 'none';
    }
    $qp->set_stemmer($self->xapian_stemmer($locale));
    $qp->set_stemming_strategy(STEM_SOME);

    $qp->set_default_op(OP_AND);

    my @prefixes = (
                    { name => author => prefix => 'A', bool => 0 },
                    { name => title  => prefix => 'S', bool => 0 },
                    { name => topic  => prefix => 'K', bool => 0 },
                    { name => source => prefix => 'XSOURCE', bool => 0 },
                    { name => notes  => prefix => 'XNOTES', bool => 0 },
                    { name => year   => prefix => 'Y', bool => 1 },
                    { name => uri   => prefix => 'Q', bool => 1 },
                   );
    foreach my $prefix (@prefixes) {
        if ($prefix->{bool}) {
            $qp->add_boolean_prefix($prefix->{name}, $prefix->{prefix});
        }
        else {
            $qp->add_prefix($prefix->{name}, $prefix->{prefix});
        }
    }

    my $flags = $args{partial} ? ( FLAG_PHRASE | FLAG_BOOLEAN  | FLAG_LOVEHATE | FLAG_WILDCARD | FLAG_SPELLING_CORRECTION | FLAG_PARTIAL)
                               : ( FLAG_PHRASE | FLAG_BOOLEAN  | FLAG_LOVEHATE | FLAG_WILDCARD | FLAG_SPELLING_CORRECTION );

    my $query = $args{query} ? $qp->parse_query($args{query}, $flags) : Search::Xapian::Query->MatchAll;

    # I belive this should be nuked, replaced by the checkboxes + help
    # for the prefixes.
    # my @additional;
    # foreach my $field (@prefixes) {
    #     if (my $term = $args{$field->{name}}) {
    #         log_debug {  "Adding " . $field->{prefix} . lc($term) };
    #         push @additional, Search::Xapian::Query->new(OP_AND,
    #                                                      map {
    #                                                          Search::Xapian::Query->new($field->{prefix} . lc($_))
    #                                                        } split (/\s+/, $term));
    #     }
    # }
    # if (@additional) {
    #     $query = Search::Xapian::Query->new(($args{match_any} ? OP_OR : OP_AND),
    #                                         ($args{query} ? ($query) : ()),
    #                                         @additional);
    # }

    my %actives;
    my @filters;
  FILTER:
    foreach my $filter (keys %SLOTS) {
        my $param_name = "filter_" . $filter;
        if (my $param = $args{$param_name}) {
            my @checked = ref($args{$param_name}) ? (@{$args{$param_name}}) : ($args{$param_name});
            foreach my $active (@checked) {
                $actives{"filter_${filter}"}{$active} = 1;
            }
            next FILTER unless $args{filters};
            if (@checked) {
                my $subquery = Search::Xapian::Query->new(+OP_OR,
                                                          map { Search::Xapian::Query
                                                              ->new($SLOTS{$filter}{prefix} . $_)
                                                          } @checked);
                Dlog_debug { "Adding filter for $filter: $_"  } \@checked;
                push @filters, $subquery;
            }
        }
    }
    if (@filters) {
        $query = Search::Xapian::Query->new(+OP_FILTER, $query, Search::Xapian::Query->new(+OP_AND, @filters));
    }
    if ($args{published_only}) {
        my $published_only = Search::Xapian::Query->new(OP_VALUE_LE,
                                                   SLOT_PUBDATE_FULL,
                                                   Search::Xapian::sortable_serialise(time()));
        log_debug { "Filtering by full date" };
        $query = Search::Xapian::Query->new(+OP_FILTER, $query, $published_only);
    }
    my $enquire = $database->enquire($query);

    my %spies;
    if ($args{facets}) {
      FACET:
        foreach my $slot (keys %SLOTS) {
            next FACET if $self->multisite && $SLOTS{$slot}{singlesite};
            my $spy = try { Search::Xapian::ValueCountMatchSpy->new($SLOTS{$slot}{slot}) };
            if ($spy) {
                $spies{$slot} = Search::Xapian::ValueCountMatchSpy->new($SLOTS{$slot}{slot});
                $enquire->add_matchspy($spies{$slot});
            }
        }
    }

    # paging
    my $pagesize = $self->page;
    my $page = $args{page};
    # be sure to have a number
    unless ($page and $page =~ m/\A([1-9][0-9]*)\z/) {
        $page = 1;
    }
    my $start = ($page - 1) * $pagesize;

    my %SORTINGS = $self->sortings;
    if ($args{sort}) {
        if ($args{sort} =~ m/\A(.+?)_(.+?)\z/) {
            my $sort = $1;
            my $direction = $2;
            if ($SORTINGS{$sort}) {
                log_debug { "Sorting $sort $direction" };
                $enquire->set_sort_by_value_then_relevance($SORTINGS{$sort},
                                                           ($direction eq 'desc' ? SORT_DESC : SORT_ASC));
            }
        }
        else {
            log_warn { "Bad value for sorting: $args{sort}" };
        }
    }

    # if no facets required, we don't need to scan everything.
    my $mset = $enquire->get_mset($start, $pagesize, $args{facets} ? $database->get_doccount : $pagesize);
    log_debug { "Total document is " . $database->get_doccount };
    # pager
    my $pager = Data::Page->new;
    $pager->total_entries($mset->get_matches_estimated);
    $pager->entries_per_page($pagesize);
    $pager->current_page($page);

    my @matches;
    foreach my $item ($mset->items) {
        my $doc = $item->get_document;
        # log_debug { $doc->get_data };
        try {
            my $data = decode_json($doc->get_data);
            push @matches, {
                            pagedata => $data,
                            relevance => $item->get_percent,
                            rank => $item->get_rank + 1,
                           };
        } catch {
            my $err = $_;
            log_error { "Cannot get JSON data from $_" . $doc->get_data }
        };
        # log_debug { join(' ', map { '<' . ($doc->get_value($SLOTS{$_}{slot}) || '') . '>'  } keys %SLOTS) };
    }
    my %facets;
    foreach my $spy_name (keys %spies) {
        my $spy = $spies{$spy_name};
        # Fetch and display the spy values
        my @got;
        my $end = $spy->values_end;
        # this is really weird, but the docs says so
      SPYLOOP:
        for (my $it = $spy->values_begin; $it != $end; $it++) {
            push @got, {
                        value => $it->get_termname,
                        count => $it->get_termfreq,
                       };
        }
        log_debug { "$spy_name went thourgh " . $spy->get_total };
        $facets{$spy_name} = \@got;
    }
    Dlog_debug { "Selections: $_ " } \%actives;
    return AmuseWikiFarm::Archive::Xapian::Result->new(
                                                       selections => \%actives,
                                                       matches => \@matches,
                                                       facets => \%facets,
                                                       pager => $pager,
                                                       multisite => $self->multisite,
                                                       site => $args{site},
                                                       lh => $args{lh},
                                                       show_deferred => $self->index_deferred,
                                                       did_you_mean => $qp->get_corrected_query_string,
                                                      );
}

sub database_is_up_to_date {
    my $self = shift;
    if (my $spec = $self->read_specification_file) {
        if ($spec->{version} and $spec->{version} == AMW_XAPIAN_VERSION) {
            return 1;
        }
    }
    return 0;
}

sub _index_html {
    my ($self, $indexer, $html) = @_;
    if (my $tree = HTML::TreeBuilder->new_from_content($html)) {
        $tree->elementify;
        my $text = $tree->as_text;
        # log_debug { "Text is $text" };
        $indexer->index_text($text);
        try {
            $indexer->index_text(Text::Unidecode::unidecode($text));
            # log_debug { Text::Unidecode::unidecode($line) };
        } catch {
            my $error = $_;
            log_warn { "Cannot unidecode $text: $_" } ;
        };
        $tree->delete;
    }
}

1;
