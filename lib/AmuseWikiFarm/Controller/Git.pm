package AmuseWikiFarm::Controller::Git;
use Moose;
use namespace::autoclean;

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
    unless ($site->cgit_integration && $site->repo_is_under_git) {
        $c->detach('/not_found');
        return;
    }
    my $cgit = $c->model('Webserver')->cgit_proxy;
    if ($cgit->disabled) {
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
    my $res = $cgit->get([ @args ], { %params });
    if ($res->success) {
        if ($res->verbatim) {
            $c->response->headers->content_type($res->content_type);
            if (my $last_modified = $res->last_modified) {
                $c->response->header('Last-Modified', $last_modified);
            }
            if (my $disposition = $res->disposition) {
                $c->response->header('Content-Disposition', $disposition);
            }
            if (my $expires = $res->expires) {
                $c->response->header('Expires', $expires);
            }
            $c->clear_encoding;
            $c->response->content_length(length($res->content));
            $c->response->body($res->content);
        }
        elsif (my $html = $res->html) {
            $c->stash(cgit_body => $html,
                      text => $text,
                      cgit_page => 1);
        }
        else {
            $c->detach('/not_found');
        }
    }
    else {
        $c->detach('/not_found');
    }
}


=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
