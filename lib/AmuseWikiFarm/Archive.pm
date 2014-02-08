package AmuseWikiFarm::Archive;

use strict;
use warnings;
use utf8;

use Moose;
use namespace::autoclean;

use Search::Xapian (':all');
use AmuseWikiFarm::Utils::Amuse qw/muse_file_info/;

has xapian => (is => 'ro',
               required => 1,
               isa => 'Str');

has repo   => (is => 'ro',
               required => 1,
               isa => 'Str');

has fields => (is => 'ro',
               isa => 'HashRef[Str]',
               lazy => 1,
               builder => '_build_fields');

has code => (is => 'ro',
             required => 1,
             isa => 'Str');

has dbic   => (is => 'ro',
               isa => 'Object');

sub _build_fields {
    my $self = shift;
    warn "Building fields\n";
    my %fields = map { $_ => 1 }
      $self->dbic->resultset('Title')->result_source->columns;
    return \%fields;
}


sub index_file {
    my ($self, $file) = @_;
    unless ($file && -f $file) {
        $file ||= '<empty>';
        warn "File $file does not exist";
        return;
    }

    my $details = muse_file_info($file, $self->code);
    # unparsable
    return unless $details;

    if ($details->{f_suffix} ne '.muse') {
        warn "Inserting data for attachment $file\n";
        $self->dbic->resultset('Attachment')->update_or_create($details);
        return $file;
    }

    # ready to store into titles?
    my %insertion;
    # lower case the keys
    foreach my $col (keys %$details) {
        my $db_col = lc($col);
        if (exists $self->fields->{$db_col}) {
            $insertion{$db_col} = delete $details->{$col};
        }
    }

    my $parsed_cats = delete $details->{parsed_categories};
    if (%$details) {
        warn "Unhandle directive in $file: " . join(", ", %$details) . "\n";
    }
    print "Inserting data for $file\n";
    # TODO: see if we have to update the insertion
    my $title = $self->dbic->resultset('Title')->update_or_create(\%insertion);
    if ($parsed_cats && @$parsed_cats) {
        # here we can die if there are duplicated uris
        $title->set_categories($parsed_cats);
    }
    return $file;
}



__PACKAGE__->meta->make_immutable;

1;
