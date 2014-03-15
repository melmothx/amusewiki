package AmuseWikiFarm::Utils::BookBuilder;
use utf8;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

use AmuseWikiFarm::Utils::Amuse qw/muse_filename_is_valid/;

has textlist => (is => 'rw',
                 isa => 'ArrayRef[Str]',
                 default => sub { [] },
                 trigger => \&_check_names,
                );

has error => (is => 'rw',
               isa => 'Str',
               default => sub { '' });

sub _check_names {
    my ($self, $list, $old_value) = @_;
    $self->error('');
    my @newlist;
    my @removed;
    foreach my $text (@$list) {
        if (muse_filename_is_valid($text)) {
            push @newlist, $text;
        }
        else {
            push @removed, $text;
        }
    }
    # modify the thing with the new list
    @$list = @newlist;
    if (@removed) {
        $self->error(join(' ', 'Removed', @removed));
    }
}

sub filename_is_valid {
    my ($self, $name) = @_;
    return muse_filename_is_valid($name);
}

sub add_text {
    my ($self, $text) = @_;
    if (muse_filename_is_valid($text)) {
        my $list = $self->textlist;
        push @$list, $text;
    }
}

sub delete_text {
    my ($self, $digit) = @_;
    $self->_modify_list(delete => $digit);
}

sub move_up {
    my ($self, $digit) = @_;
    $self->_modify_list(up => $digit);
}

sub move_down {
    my ($self, $digit) = @_;
    $self->_modify_list(down => $digit);
}

sub _modify_list {
    my ($self, $operation, $digit) = @_;
    return unless ($digit and $digit =~ m/^[1-9][0-9]*$/);
    my $index = $digit - 1;
    return if $index < 0;
    my $list = $self->textlist;
    return unless exists $list->[$index];

    # deletion
    if ($operation eq 'delete') {
        splice(@$list, $index, 1);
        return;
    }

    # swapping
    my $replace = $index;

    if ($operation eq 'up') {
        $replace--;
        return if $replace < 0;
    }
    elsif ($operation eq 'down') {
        $replace++;
    }
    else {
        die "Wrong op $operation";
    }
    return unless exists $list->[$replace];

    # and swap
    my $tmp = $list->[$replace];
    $list->[$replace] = $list->[$index];
    $list->[$index] = $tmp;
    # all done
}

sub delete_all {
    shift->textlist([]);
}

=head2 texts

Return a copy of the text list.

=cut

sub texts {
    return [ @{ shift->textlist } ];
}



__PACKAGE__->meta->make_immutable;

1;
