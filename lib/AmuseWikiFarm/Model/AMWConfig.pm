package AmuseWikiFarm::Model::AMWConfig;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';

=head1 NAME

AmuseWikiFarm::Model::AMWConfig - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.


=encoding utf8

=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

has ckeditor_use_cdn => ( is => 'ro',
                          isa => 'Bool');

__PACKAGE__->meta->make_immutable;

1;
