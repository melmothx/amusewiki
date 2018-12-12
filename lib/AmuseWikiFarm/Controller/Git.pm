package AmuseWikiFarm::Controller::Git;
use Moose;
with 'AmuseWikiFarm::Role::Controller::HumanLoginScreen';
use namespace::autoclean;

use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Archive::CgitEmulated;
use Encode qw/decode/;

BEGIN { extends 'Catalyst::Controller'; }

=encoding utf8

=head1 NAME

AmuseWikiFarm::Controller::Git - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 root

=cut

sub git :Chained('/site') :Args {
    my ($self, $c, @args) = @_;
    my $site = $c->stash->{site};
    # do not permit leading dots and URI encoded strings. We have all
    # the repo in ascii anyway.
    my $invalid = 0;
    foreach my $arg (@args) {
        $invalid++ unless $arg =~ m/\A[0-9a-zA-Z_-]+(\.[0-9a-zA-Z]+)*/;
    }
    if ($invalid) {
        $c->detach('/bad_request');
        return;
    }
    unless ($site->repo_is_under_git) {
        # can't be helped, it's a 404, nothing to show.
        $c->detach('/not_found');
        return;
    }
    # we show /git to users and require authentication if
    # cgit_integration is false.
    $self->check_login($c) unless $site->cgit_integration;

    my $cgit = AmuseWikiFarm::Archive::CgitEmulated->new;
    unless ($cgit->enabled) {
        $c->detach('/not_found');
        return;
    }
    unless (@args) {
        push @args, $site->id;
    }
    if ($args[0] ne $site->id) {
        $c->detach('/not_found');
        return;
    }
    my $text;
    if (my @muse = grep { /[a-z0-9]\.muse$/ } @args) {
        my $file = pop @muse;
        $file =~ s/\.muse$//;
        my $f_class = 'text';
        if (grep { $_ eq 'specials' } @args) {
            $f_class = 'special';
        }
        $text = $site->titles->search({uri => $file, f_class => $f_class })->first;
    }


    my %params = %{ $c->request->params };
    my $res = $cgit->get([ @args ], { %params }, $c->request->env);
    if (my ($status) = $res->headers->remove_header('Status')) {
        log_debug { "Status is $status" } ;
        if ($status =~ m/(\d{3})/a) {
            if ($status and $status ne '200') {
                $c->response->status($1);
                $c->response->body("Not found");
                return;
            }
        }
    }

    my %headers = $res->headers->flatten;
    Dlog_debug { "Headers are $_" } \%headers;
    $c->response->header(%headers);

    if ($res->headers->header('Content-Disposition')) {
        # now, here we trust both Catalyst and the HTTP::Message
        # module to do the right thing about the encoding/decoding.
        # And let's hope for the best. Seems to work, though.
        $c->response->body($res->decoded_content);
        $c->detach;
    }
    elsif ($res->content_type =~ m/text\/html/) {
        $c->stash(cgit_body => $res->decoded_content,
                  text => $text,
                  cgit_page => 1);
    }
    else {
        $c->detach('/not_found');
    }
}


=head1 AUTHOR

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
