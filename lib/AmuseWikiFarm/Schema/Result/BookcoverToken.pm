use utf8;
package AmuseWikiFarm::Schema::Result::BookcoverToken;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::BookcoverToken - Book Cover Template Tokens

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

=head1 TABLE: C<bookcover_token>

=cut

__PACKAGE__->table("bookcover_token");

=head1 ACCESSORS

=head2 bookcover_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 token_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 token_value

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "bookcover_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "token_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "token_value",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</bookcover_id>

=item * L</token_name>

=back

=cut

__PACKAGE__->set_primary_key("bookcover_id", "token_name");

=head1 RELATIONS

=head2 bookcover

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Bookcover>

=cut

__PACKAGE__->belongs_to(
  "bookcover",
  "AmuseWikiFarm::Schema::Result::Bookcover",
  { bookcover_id => "bookcover_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2024-01-28 08:28:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vGU3aG7IMvIXxx63U3Z/mQ

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'bookcover_token_name_amw_index', fields => ['token_name']);
}


use AmuseWikiFarm::Log::Contextual;
use Text::Amuse::Functions qw/muse_to_object muse_format_line/;

has token_type => (is => 'ro', isa => 'Str', lazy => 1, builder => '_build_token_type');
has label => (is => 'ro', isa => 'Str', lazy => 1, builder => '_build_label');

sub _build_token_type {
    my $self = shift;
    if ($self->token_name =~ m/\A[a-z_]+_(int|muse_str|muse_body|float|file|isbn)\z/) {
        return $1;
    }
    return "";
}

sub _build_label {
    my $self = shift;
    if ($self->token_name =~ m/\A([a-z_]+)_(int|muse_str|muse_body|float|file|isbn)\z/) {
        my $label = $1;
        return join(' ', map { ucfirst($_) } split(/_/, $label));
    }
    return "";
}


sub _validate {
    my ($self, $value) = @_;
    return undef unless defined $value;
    # log_debug { "Value is $value" };
    if (my $type = $self->token_type) {
        my %checks = (
                      int =>   qr{0|[1-9][0-9]*},
                      float => qr{[0-9]+(?:\.[0-9]+)?},
                      muse_body =>  qr{.*}s,
                      muse_str =>  qr{.*}s, # we're mangling the new lines anyway
                      file =>  qr{[0-9a-z-]+\.(?:pdf|png|jpe?g)},
                      isbn => qr{isbn-[0-9-]{10,}\.pdf},
                     );
        if (my $re = $checks{$type}) {
            if ($value =~ m/\A($re)\z/) {
                my $valid = $1;
                return $valid;
            }
        }
    }
    log_debug { "Invalid value" };
    return undef;
}

sub token_value_for_form {
    my $self = shift;
    my $validated = $self->_validate($self->token_value);
    if ($validated and $self->token_type eq 'isbn') {
        $validated =~ s/isbn-([0-9-]{10,})\.pdf/$1/;
    }
    return $validated;
}

sub token_value_for_template {
    my $self = shift;
    my $validated = $self->_validate($self->token_value);
    my $token_type = $self->token_type;
    my %trans = (
                 float => sub { return $_[0] },
                 int => sub { return $_[0] },
                 muse_body => sub {
                     my $str = $_[0];
                     my $latex = muse_to_object($str)->as_latex;
                     $latex =~ s/\A\s*//s;
                     $latex =~ s/\s*\z//s;
                     return $latex;
                 },
                 muse_str => sub {
                     my $str = $_[0];
                     $str =~ s/\s+/ /gs;
                     $str =~ s/<\s*br\s*\/*\s*>/ /gs;
                     my $latex = muse_format_line(ltx => $str);
                     $latex =~ s/\A\s*//s;
                     $latex =~ s/\s*\z//s;
                     return $latex;
                 },
                 file => sub {
                     my $fname = $_[0];
                     if ($fname =~ m/\A(f[0-9]+\.(pdf|png|jpe?g))\z/) {
                         return $1;
                     }
                     return '';
                 },
                 isbn => sub {
                     my $fname = $_[0];
                     if ($fname =~ m/\A(isbn-[0-9-]+\.pdf)\z/) {
                         return $1;
                     }
                     return '';
                 }
                );
    if (defined($validated)) {
        if (my $sub = $trans{$token_type}) {
            return $sub->($validated);
        }
    }
    # still here?
    if ($token_type eq 'int' or $token_type eq 'float') {
        return 0;
    }
    else {
        return '';
    }
}

sub update_if_valid {
    my ($self, $value) = @_;
    my $validated = $self->_validate($value);
    # log_debug { "Validated value is $validated" };
    $self->update({ token_value => $validated });
}

__PACKAGE__->meta->make_immutable;
1;
