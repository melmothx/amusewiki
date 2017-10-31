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
    my $token;
    if ($c->sessionid) {
        if (my $data = $c->session->{bookbuilder}) {
            %args = %$data;
            Dlog_debug { "Bookbuilder's session loaded with $_" } \%args;
        }
        $token = $c->session->{bookbuilder_token};
    }
    # load the default from the site settings.
    my $site = $c->stash->{site};
    if ($site and !%args) {
        %args = $site->bb_values;
        Dlog_debug { "Loading defaults from site " . $_ } \%args;
    }
    if ($token) {
        $args{token} = $token;
    }
    $args{user_is_logged_in} = $c->user_exists;
    $args{dbic} = $c->model('DB');
    $args{site} = $site if $site;
    # this switched from boolean to string and it was a long time ago.
    $args{headings} ||= 0;
    delete $args{signature}; # legacy
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
