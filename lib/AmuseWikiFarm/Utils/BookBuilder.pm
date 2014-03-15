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



__PACKAGE__->meta->make_immutable;

1;
