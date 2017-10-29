package AmuseWikiFarm::Schema::ResultSet::GlobalSiteFile;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head1 NAME

AmuseWikiFarm::Schema::Result::GlobalSiteFile - Global Site File RS

=head1 METHODS

=cut

use AmuseWikiFarm::Log::Contextual;

sub app_files {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.file_type" => 'application' });
}

sub thumbnails {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.file_type" => 'thumbnail' });
}

1;
