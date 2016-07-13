package AmuseWikiFarm::Controller::Monthly;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Monthly - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub base :Chained('/site_robot_index') :PathPart('monthly') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};
    if ($c->request->query_params->{bare}) {
        $c->stash(no_wrapper => 1);
    }
    my $archives = $site->monthly_archives
      ->search(undef,
               {
                order_by => { -desc => [qw/year month/] },
                prefetch => [qw/text_months/],
               });
    $c->stash(monthly_archives => $archives,
              template => 'monthly/list.tt',
              page_title => $c->loc('Archive by month'),
              nav => 'monthly',
              breadcrumbs => [{
                               uri => $c->uri_for_action('/monthly/list'),
                               label => $c->loc('Archive by month'),
                              }],
             );
}

sub list :Chained('base') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
}

sub year :Chained('base') :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $year) = @_;
    unless ($year and $year =~ m/\A[0-9]+\z/) {
        $c->detach('/not_found');
        return;
    }
    $c->stash->{monthly_archives} = $c->stash->{monthly_archives}->search({ year => $year });
    push @{$c->stash->{breadcrumbs}},
      {
       uri => $c->uri_for_action('/monthly/year_display', [ $year ]),
       label => $year,
      };
    $c->stash->{page_title} .= " ($year)";
}

sub year_display :Chained('year') :PathPart('') :Args(0) {}

sub month :Chained('year') :PathPart('') :Args(1) {
    my ($self, $c, $month) = @_;
    my $site = $c->stash->{site};
    unless ($month and $month =~ m/\A[0-9]+\z/) {
        $c->detach('/not_found');
        return;
    }
    my $page = $c->request->query_params->{page};
    unless ($page and $page =~ m/\A[1-9][0-9]*\z/) {
        $page = 1;
    }
    if (my $arch = $c->stash->{monthly_archives}->find({ month => $month })) {
        my $texts = $arch->titles->published_texts
        ->search(undef, {
                         order_by => { -desc => 'pubdate' },
                         page => $page,
                         rows => $site->pagination_size,
                        });
        my $pager = $texts->pager;
        my @uri_args = ($arch->year, $arch->month);
        my $format_link = sub {
            return $c->uri_for_action('/monthly/month', \@uri_args, { page => $_[0] });
        };
        my $month_name = $arch->localized_name($c->stash->{current_locale_code});
        $c->stash(month_name => $month_name,
                  page_title => $month_name,
                  pager => AmuseWikiFarm::Utils::Paginator::create_pager($pager,
                                                                         $format_link),
                  template => 'monthly/month.tt',
                  texts => $texts);
        push @{$c->stash->{breadcrumbs}},
          { uri => $c->uri_for_action('/monthly/month', [ $arch->year,
                                                          $arch->month,
                                                        ]),
            label => $arch->datetime($c->stash->{current_locale_code})->month_name,
          };
        return;
    }
    $c->detach('/not_found');
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
