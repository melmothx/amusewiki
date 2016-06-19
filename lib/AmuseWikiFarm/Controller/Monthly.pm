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
    my $archives = $site->monthly_archives
      ->search(undef,
               { order_by => { -desc => [qw/year month/] } });
    $c->stash(monthly_archives => $archives);
}

sub list :Chained('base') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash(monthly_archives_list => [ $c->stash->{monthly_archives}->all ],
              template => 'monthly/list.tt');
}

sub list_display :Chained('list') :PathPart('') :Args(0) {
}

sub bare :Chained('list') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(no_wrapper => 1);
}

sub month :Chained('base') :PathPart('') :Args(2) {
    my ($self, $c, $year, $month) = @_;
    if ($year and $month and
        $year =~ m/\A[0-9]+\z/ and
        $month =~ m/\A[0-9]+\z/) {
        if (my $arch = $c->stash->{monthly_archives}->find({
                                                            year => $year,
                                                            month => $month,
                                                           })) {
            my @texts = $arch->titles->published_texts
              ->search(undef, {
                               order_by => { -desc => 'pubdate' },
                              });
            $c->stash(month_name => $arch->localized_name($c->stash->{current_locale_code}),
                      texts => \@texts);
            return;
        }
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
