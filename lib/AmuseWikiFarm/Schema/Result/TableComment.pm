use utf8;
package AmuseWikiFarm::Schema::Result::TableComment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::TableComment - Table comments, used internally

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

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<table_comments>

=cut

__PACKAGE__->table("table_comments");

=head1 ACCESSORS

=head2 table_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 comment_text

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "table_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "comment_text",
  { data_type => "text", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-02-17 19:36:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xx6eHb8qbSjfZGyTraa0vQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
