use utf8;
package AmuseWikiFarm::Schema::Result::Redirection;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Redirection

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::PassphraseColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "PassphraseColumn");

=head1 TABLE: C<redirection>

=cut

__PACKAGE__->table("redirection");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 uri

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 type

  data_type: 'varchar'
  is_nullable: 0
  size: 16

=head2 redirect

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "uri",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 16 },
  "redirect",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<uri_type_site_id_unique>

=over 4

=item * L</uri>

=item * L</type>

=item * L</site_id>

=back

=cut

__PACKAGE__->add_unique_constraint("uri_type_site_id_unique", ["uri", "type", "site_id"]);

=head1 RELATIONS

=head2 site

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Site>

=cut

__PACKAGE__->belongs_to(
  "site",
  "AmuseWikiFarm::Schema::Result::Site",
  { id => "site_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07040 @ 2014-08-11 10:20:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3kHGaJh8DTxA7hPBlktx8Q

=head1 REDIRECTIONS

Redirections happen only within the same scope and the same target.
I.e., a title alias will always refer to another title, not to a
special page nor a topic nor a title.

=cut

sub uri_prefix {
    my $self = shift;
    my $uri_map = {
                   text => 'library',
                   topic => 'topics',
                   author => 'authors',
                   special => 'specials',
                  };
    my $prefix = $uri_map->{$self->type};
    die "Unhandle type " . $self->type unless $prefix;
    return $prefix;
}


sub full_dest_uri {
    my $self = shift;
    return '/' . $self->uri_prefix . '/' . $self->redirect;
}

sub full_src_uri {
    my $self = shift;
    return '/' . $self->uri_prefix . '/' . $self->uri;
}

sub target_table {
    my $self = shift;
    my $type = $self->type;
    if ($type eq 'topic' or $type eq 'author' or $type eq 'category') {
        return 'category';
    }
    else {
        return 'title';
    }
}

sub can_safe_delete {
    return shift->is_a_category;
}

sub is_a_text {
    my $self = shift;
    if ($self->target_table eq 'title') {
        return 1;
    }
    else {
        return;
    }
}

sub is_a_category {
    my $self = shift;
    if ($self->target_table eq 'category') {
        return 1;
    }
    else {
        return;
    }
}

sub linked_category {
    my $self = shift;
    my $cat = $self->site->categories->find({
                                             type => $self->type,
                                             uri => $self->redirect,
                                            });
    $cat ? return $cat : return;
}

sub aliased_category {
    my $self = shift;
    my $cat = $self->site->categories->find({
                                             type => $self->type,
                                             uri => $self->uri,
                                            });
    $cat ? return $cat : return;
}


sub linked_texts {
    my $self = shift;
    if ($self->is_a_category) {
        if (my $cat = $self->linked_category) {
            return $cat->titles;
        }
    }
    elsif ($self->is_a_text) {
        my $title = $self->site->titles->find({
                                               f_class => $self->type,
                                               uri => $self->redirect,
                                              });
        if ($title) {
            return $title;
        }
    }
    else {
        die "WTF? " . join(" ", $self->type, $self->uri, $self->redirect) . "\n";
    }
    return;
}


__PACKAGE__->meta->make_immutable;

1;
