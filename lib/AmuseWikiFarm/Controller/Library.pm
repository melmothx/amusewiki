package AmuseWikiFarm::Controller::Library;
use Moose;
with qw/AmuseWikiFarm::Role::Controller::RegularListing
        AmuseWikiFarm::Role::Controller::ListingDisplay
        AmuseWikiFarm::Role::Controller::Text/;

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;

=head1 NAME

AmuseWikiFarm::Controller::Library - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 WHY THIS CLASS IS ALMOST EMPTY

22:17 <@mst> have two controllers that consume the role
22:17 <@mst> that then means both are first class citizens
22:17 <@mst> because the role can contain the relevant chain parts
22:17 <@mst> and now you have shared code *and* working uri_for_action
22:18 < melmothX_> mm, is there some example around?
22:22 < melmothX_> ah, now I think I understand what do you mean
22:23 < melmothX_> mst: thanks, I think it should work once i figure out how to write it
22:24 < melmothX_> so both controller will have just the first chaining, + role with the endpoints . am I understand correctly?
22:25 <@mst> right. remember you can chain between controllers too though
22:25 <@mst> so you can have a Controller::Thing with the base line stuff
22:25 <@mst> then Controller::Thing::Library and Controller::Thing::Special
22:26 <@mst> with 'MyApp::ControllerRole::SubThing'; sub base :Chained('/thing/some_method') :PathPart('library') :CaptureArgs(0) {
             ... }
22:26 <@mst> and ::SubThing has 'sub common_method :Chained('base') ...

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

=head2 bbselect

Display a splat text in a table for selection.

=cut

sub bbselect :Chained('match') PathPart('bbselect') :Args(0) {
    my ($self, $c) = @_;
    log_debug { "In bbselect" };
    $c->stash(base_url => $c->uri_for('/library/'));
}

=encoding utf8

=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
