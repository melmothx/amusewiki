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

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my $site = $c->stash->{site};
    my $xapian = $site->xapian;
    # here we could configure the paging
    # $xapian->page(1);

    my $query = $c->req->params->{query};
    my %params = %{ $c->req->params };
    if (delete $params{complex_query}) {
        delete $params{fmt};
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

    my ($matches, @results) = $xapian->search($query, $page);
    foreach my $res (@results) {
        $res->{text} = $site->titles->by_uri($res->{pagename});
    }

    my $paging = $xapian->page;

    my $last_thing = (($page - 1) * $paging) + scalar(@results);

    my $range;
    if (@results) {
        $range = $results[0]->{rank} . '-' . $results[$#results]->{rank};
    }

    $c->stash( matches => $matches,
               range => $range,
               built_query => $query,
               page_title => $c->loc('Search'),
               results => \@results );




    $c->log->debug("$last_thing, $matches, " . scalar(@results));

    if ($matches > $paging  && $last_thing < $matches) {
        $c->stash(next_page => $c->uri_for($c->action, { page => $page + 1,
                                                         query => $query }));
    }

    if ($page > 1) {
        $c->stash(previous_page => $c->uri_for($c->action, { page => $page - 1,
                                                             query => $query }));
    }
}




=encoding utf8

=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
