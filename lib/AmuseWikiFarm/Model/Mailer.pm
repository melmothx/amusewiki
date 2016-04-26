package AmuseWikiFarm::Model::Mailer;

use strict;
use warnings;
use base 'Catalyst::Model::Adaptor';
use AmuseWikiFarm::Log::Contextual;
use Path::Tiny;

__PACKAGE__->config(
    class => 'AmuseWikiFarm::Utils::Mailer',
);

sub prepare_arguments {
    my ($self, $app) = @_;
    my %opts = (mkit_location => $app->path_to('mkits')->stringify);
    Dlog_debug { "Loading lexicon with $_" } \%opts;
    return \%opts;
}
