package AmuseWikiFarm::Controller::Library;
use Moose;
with qw/AmuseWikiFarm::Role::Controller::RegularListing
        AmuseWikiFarm::Role::Controller::ListingDisplay
        AmuseWikiFarm::Role::Controller::Text/;

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


=head1 NAME

AmuseWikiFarm::Controller::Library - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 root

Empty base method to start the chain

=cut

=over 4

=item regular_list

Mapping to /library

=item regular_list_display

Forward to C<template_listing>

=item special_list

Mapping to /special

=item special_list_display

Forward to C<template_listing>

=item template_listing

Render the library.tt template using the texts in the C<texts_rs>
stash.

=back

=cut

sub pre_base :Chained('/site_robot_index') :PathPart('library') :CaptureArgs(0) {}



=head2 text

Path: /library/*

Main method to serve the files, mapping them to the real location.

=cut



=encoding utf8

=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
