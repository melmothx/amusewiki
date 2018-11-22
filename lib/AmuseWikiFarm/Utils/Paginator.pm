package AmuseWikiFarm::Utils::Paginator;

use utf8;
use strict;
use warnings;

=head1 NAME

AmuseWikiFarm::Utils::Paginator - amusewiki paginator routine

=head2 create_pager($pager, $sub)

Return an arrayref of hashref with the following keys: C<uri>,
C<label>, C<active>.

The first argument must be a L<Data::Page> object, while the
second must be a coderef, which will be called as 

  my $url = $sub->($page)

=cut

use AmuseWikiFarm::Utils::Paginator::Object;
use AmuseWikiFarm::Log::Contextual;

sub create_pager {
    my ($pager, $sub) = @_;
    my @pages;
    my %done;
    my $current = $pager->current_page;
    my $first = $pager->first_page;
    my $last = $pager->last_page;

    my %args = (current_url => $current,
                next_url => $pager->next_page,
                prev_url => $pager->previous_page);
    foreach my $k (keys %args) {
        if (defined $args{$k}) {
            $args{$k} = $sub->($args{$k}) . '';
        }
    }
    Dlog_debug { "args: $_ "} \%args;

    my $expected = 1;
    foreach my $spec ({
                       label => '<i class="fa fa-chevron-left"></i><span class="sr-only">«<span>',
                       page => $pager->previous_page,
                      },
                      {
                       page => $first
                      },
                      {
                       page => $first + 1,
                      },
                      {
                       page => $current - 2,
                      },
                      {
                       page => $current - 1,
                      },
                      {
                       page => $current,
                      },
                      {
                       page => $current + 1,
                      },
                      {
                       page => $current + 2,
                      },
                      {
                       page => $last - 1,
                      },
                      {
                       page => $last,
                      },
                      {
                       label => '<i class="fa fa-chevron-right"></i><span class="sr-only">»<span>',
                       page => $pager->next_page,
                      }) {
        my $page = $spec->{page};
        if ($page && $page >= $first && $page <= $last) {
            unless ($spec->{label}) {
                if ($done{$page}) {
                    next;
                }
                else {
                    $done{$page} = 1;
                }
                if ($expected < $page) {
                    push @pages, { label => '...' };
                }
            }
            my %out = (
                       uri => $sub->($page) . '',
                       label => $spec->{label} || $page,
                      );
            if ($page == $current) {
                $out{active} = 1;
            }
            $expected = $page + 1;
            push @pages, \%out;
        }
    }
    return AmuseWikiFarm::Utils::Paginator::Object->new(items => \@pages,
                                                        %args);
}

1;    
