package AmuseWikiFarm::Controller::Latest;
use utf8;
use Moose;
with qw/AmuseWikiFarm::Role::Controller::RegularListing/;

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;

=head1 NAME

AmuseWikiFarm::Controller::Latest - Catalyst Controller for latest entries.

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 pre_base

=cut

sub pre_base :Chained('/site_robot_index') :PathPart('latest') :CaptureArgs(0) {}

sub index :Chained('base') :PathPart('') :Args {
    my ($self, $c, $page) = @_;
    log_debug { "requested /latest/ $page" };
    unless ($page and $page =~ m/\A[1-9][0-9]*\z/) {
        $page = 1;
    }
    my $results = $c->stash->{texts_rs}->search(undef,
                                                {
                                                 order_by => { -desc => 'pubdate' },
                                                 page => $page,
                                                 rows => 20,
                                                });
    my $pager = $results->pager;
    my $format_link = sub {
        return $c->uri_for_action('/latest/index', $_[0]);
    };
    my @res = $results->all;
    $c->stash(pager => $self->create_pager($pager, $format_link),
              nav => 'latest',
              page_title => $c->loc('Latest entries'),
              texts => \@res);
}

sub create_pager {
    my ($self, $pager, $sub) = @_;
    my @pages;
    my %done;
    my $current = $pager->current_page;
    my $first = $pager->first_page;
    my $last = $pager->last_page;

    foreach my $spec ({
                       label => "«««",
                       page => $pager->previous_page,
                      },
                      {
                       page => $first
                      },
                      {
                       page => $first + 1,
                      },
                      {
                       page => $first + 2,
                      },
                      {
                       page => $first + 3,
                      },
                      {
                       page => $current - 3,
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
                       page => $current + 3,
                      },
                      {
                       page => $last -3,
                      },
                      {
                       page => $last -2,
                      },
                      {
                       page => $last -1,
                      },
                      {
                       page => $last,
                      },
                      {
                       label => "»»»",
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
            }
            my %out = (
                       uri => $sub->($page),
                       label => $spec->{label} || $page,
                      );
            if ($page == $current) {
                $out{active} = 1;
            }
            push @pages, \%out;
        }
    }
    Dlog_debug { "$_" } \@pages;
    return \@pages;
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
