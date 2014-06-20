package AmuseWikiFarm::Controller::Category;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Category - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 Category listing

=head3 authors

The list of authors

=head3 authors/<name>

Details about the author <name>

=head3 topics

The list of topics

=head3 topics/<name>

=cut

sub auto :Private {
    my ($self, $c) = @_;
    $c->stash(please_index => 1);
}


sub root :Chained('/') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub authors :Chained('root') :PathPart('authors') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->forward(category_list => [qw/author/]);
}

sub topics :Chained('root') :PathPart('topics') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->forward(category_list => [qw/topic/]);
}

sub category_list :Private {
    my ($self, $c, $type) = @_;
    my $rs = $c->stash->{site}->categories->by_type($type)
      ->search({
                text_count => { '>' => 0 },
               });
    $c->stash(
              nav => $type,
              categories_rs => $rs,
              f_class => $type,
             );
}

sub authors_listing :Chained('authors') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(page_title => $c->loc('Authors'));
    $c->forward('category_list_display');
}

sub topics_listing :Chained('topics') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(page_title => $c->loc('Topics'));
    $c->forward('category_list_display');
}

sub category_list_display :Private {
    my ($self, $c) = @_;
    my @list = $c->stash->{categories_rs}->all;
    $c->stash(list => \@list,
              template => 'category.tt');
}

sub single_topic :Chained('topics') :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $uri) = @_;
    $c->forward(single_category => [$uri]);
}

sub single_author :Chained('authors') :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $uri) = @_;
    $c->forward(single_category => [$uri]);
}

sub single_category :Private {
    my ($self, $c, $uri) = @_;
    my $cat = $c->stash->{categories_rs}->find({ uri => $uri });
    if ($cat) {
        $c->stash(page_title => $cat->name,
                  template => 'category-details.tt',
                  category => $cat);
    }
    else {
        $c->detach('/not_found');
    }
}


sub single_topic_display :Chained('single_topic') :PathPart('') :Args(0) {}

sub single_author_display :Chained('single_author') :PathPart('') :Args(0) {}



=encoding utf8

=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
