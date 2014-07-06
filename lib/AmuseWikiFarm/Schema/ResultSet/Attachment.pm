package AmuseWikiFarm::Schema::ResultSet::Attachment;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';


=head2 by_uri

Find an attachment by uri

=cut

sub by_uri {
    my ($self, $uri) = @_;
    return $self->single({ uri => $uri });
}

=head2 pdf_by_uri

As above, but assert the class is C<upload_pdf>

=cut

sub pdf_by_uri {
    my ($self, $uri) = @_;
    return $self->single({
                          uri => $uri,
                          f_class => 'upload_pdf',
                         });
}

=head2 find_file($path)

Shortcut for

 $self->search({ f_full_path_name => $path })->single;

=cut

sub find_file {
    my ($self, $path) = @_;
    die "Bad usage" unless $path;
    return $self->search({ f_full_path_name => $path })->single;
}



1;

