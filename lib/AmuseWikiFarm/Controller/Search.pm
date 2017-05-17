package AmuseWikiFarm::Controller::Search;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Search - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Utils::Paginator;
use Data::Page;

sub opensearch :Chained('/site_no_auth') :PathPart('opensearch.xml') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(no_wrapper => 1);
    $c->res->content_type('application/xml');
}

sub index :Chained('/site') :PathPart('search') :Args(0) {
    my ( $self, $c ) = @_;
    my $site = $c->stash->{site};
    my $xapian = $site->xapian;
    # here we could configure the paging
    # $xapian->page(1);

    my $query = $c->req->params->{query};
    my %params = %{ $c->req->params };
    if (delete $params{complex_query}) {
        delete $params{fmt};
        delete $params{page};
        my $match_any = delete $params{match_any};
        my @tokens = (delete $params{query});
        foreach my $k (keys %params) {
            my $string = $params{$k};
            next unless $string =~ m/\w/;
            $string =~ s/["<>]//g;
            $string =~ s/^\s+//;
            $string =~ s/\s+$//;
            push @tokens, qq{$k:"$string"};
        }
        my $joiner = $match_any ? ' OR ' : ' AND ';
        $query = join($joiner, grep { defined and m/\w/ } @tokens);
    }

    my $page = 1;
    if ($c->req->params->{page} and
        $c->req->params->{page} =~ m/([1-9][0-9]*)/) {
        $page = $1;
    }

    my ($pager, @results);
    eval {
        ($pager, @results) = $xapian->search($query, $page,
                                             $c->stash->{current_locale_code});
    };
    if ($@) {
        Dlog_error { "Xapian error: " . $c->request->uri . ": $@ " . $_ } ($c->request->params);
        $c->stash(xapian_errors => "$@");
        $pager = Data::Page->new;
    }

    foreach my $res (@results) {
        $res->{text} = $site->titles->texts_only->by_uri($res->{pagename})->single;
        unless ($res->{text} and
                $xapian->text_can_be_indexed($res->{text})) {
            log_error {
                "Search returned $res->{pagename} but not present, removing during " .
                  $c->request->uri;
            };
            eval { $xapian->delete_text_by_uri($res->{pagename}) };
        }
    }

    if ($c->req->params->{fmt} and $c->req->params->{fmt} eq 'json') {
        my @unrolled;
        foreach my $res (@results) {
            if (my $txt = $res->{text}) {
                push @unrolled, {
                                 title => $txt->title,
                                 author => $txt->author,
                                 url => $c->uri_for($txt->full_uri)->as_string,
                                };
            }
        }
        $c->stash(json => \@unrolled);
        $c->detach($c->view('JSON'));
        return;
    }
    my $format_link = sub {
        return $c->uri_for($c->action, { page => $_[0], query => $query });
    };
    $c->stash( pager => AmuseWikiFarm::Utils::Paginator::create_pager($pager, $format_link),
               built_query => $query,
               page_title => $c->loc('Search'),
               results => \@results );
}




=encoding utf8

=head1 AUTHOR

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
