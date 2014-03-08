package AmuseWikiFarm::Model::Xapian;

use strict;
use warnings;
use base 'Catalyst::Model::Factory::PerRequest';

__PACKAGE__->config(
    class => 'AmuseWikiFarm::Xapian',
);

sub prepare_arguments {
    my ($self, $c) = @_;
    $c->log->debug("Loading xapian search");
    return { site => $c->stash->{site}->id };
}


=head1 NAME

AmuseWikiFarm::Model::Xapian - Catalyst Xapian Schema Model

=head1 SYNOPSIS

See L<AmuseWikiFarm>

=head1 DESCRIPTION

Wrap L<AmuseWikiFarm::Model::Xapian> into the catalyst app

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
