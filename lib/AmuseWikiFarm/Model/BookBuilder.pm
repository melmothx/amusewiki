package AmuseWikiFarm::Model::BookBuilder;

use strict;
use warnings;
use base 'Catalyst::Model::Factory::PerRequest';

use AmuseWikiFarm::Log::Contextual;

__PACKAGE__->config(
    class => 'AmuseWikiFarm::Archive::BookBuilder',
);

sub prepare_arguments {
    my ($self, $c) = @_;
    # WARNING: here the $c->session->{bookbuilder}->{textlist} get
    # passed directly, hence any modification done in it, will be
    # reflected in the session. At some point, we could pass a copy
    # here instead, but it seems to work as expected...
    my %args;
    if ($c->sessionid) {
        if (my $data = $c->session->{bookbuilder}) {
            %args = %$data;
        }
        if (my $token = $c->session->{bookbuilder_token}) {
            $args{token} = $token;
        }
    }
    $args{user_is_logged_in} = $c->user_exists;
    Dlog_debug { "Bookbuilder loading with $_" } \%args;
    $args{dbic} = $c->model('DB');
    if (my $site = $c->stash->{site}) {
        $args{site} = $site;
    }
    # this switched from boolean to string
    $args{headings} ||= 0;
    return \%args;
}


=head1 NAME

AmuseWikiFarm::Model::BookBuilder - Bookbuilder helper model

=head1 SYNOPSIS

See L<AmuseWikiFarm>

=head1 DESCRIPTION

Wrap L<AmuseWikiFarm::Archive::BookBuilder> into the catalyst app

=head1 AUTHOR

Marco

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

# Local Variables:
# cperl-indent-parens-as-block: t
# End:
