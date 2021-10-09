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

sub public_files {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.file_type" => 'public' });
}

# See Attachments::generate_thumbnails

sub thumb {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.image_width" => 36 });
}

sub small {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.image_width" => 150 });
}

sub large {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.image_width" =>  300 });
}

sub min_dimensions {
    my ($self, $w, $h) = @_;
    my $me = $self->current_source_alias;
    return $self->search({
                          "$me.image_width" =>  { '>' => $w || 0 },
                          "$me.image_height" =>  { '>' => $h || 0 }
                         });
}

1;
