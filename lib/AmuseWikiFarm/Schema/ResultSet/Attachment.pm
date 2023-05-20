package AmuseWikiFarm::Schema::ResultSet::Attachment;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head1 NAME

AmuseWikiFarm::Schema::ResultSet::Attachment - attachment resultset

=head1 METHODS

=head2 by_uri($uri)

Find an attachment by uri

=cut

sub by_uri {
    my ($self, $uri) = @_;
    return $self->single({ uri => $uri });
}

=head2 pdf_by_uri($uri)

As above, but assert the class is C<upload_pdf>

=cut

sub pdf_by_uri {
    my ($self, $uri) = @_;
    return $self->single({
                          uri => $uri,
                          f_class => 'upload_pdf',
                         });
}

sub binary_by_uri {
    my ($self, $uri) = @_;
    my $me = $self->current_source_alias;
    return $self->single({
                          "$me.uri" => $uri,
                          "$me.f_class" => [qw/upload_pdf upload_binary/],
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

sub images_only {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.f_class" => "image" });
}

sub with_descriptions {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search([
                          { "$me.title_muse"   => { '!=' => '' } },
                          { "$me.comment_muse" => { '!=' => '' } },
                          { "$me.alt_text"   => { '!=' => '' } },
                         ]);
}

sub public_only {
    my $self = shift;
    my $me = $self->current_source_alias;
    # ignore "attachment" which is the staging name. This ones have a valid uri.
    return $self->search({
                          "$me.f_class" => [qw/special_image
                                               image
                                               upload_binary
                                               upload_pdf/]
                         });
}

sub excluding_ids {
    my ($self, $ids) = @_;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.id" => { -not_in => $ids } });
}

sub orphans {
    my ($self) = @_;
    my $me = $self->current_source_alias;
    $self->search(undef,
                  {
                   join => 'title_attachments',
                   distinct => 1, # generates group by
                   having => \'COUNT(title_attachments.title_id) = 0'
                  });
}

1;

