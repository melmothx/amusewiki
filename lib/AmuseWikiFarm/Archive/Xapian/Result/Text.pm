package AmuseWikiFarm::Archive::Xapian::Result::Text;
use utf8;
use strict;
use warnings;

=head1 NAME

AmuseWikiFarm::Archive::Xapian::Result::Text - Duck-typed Title from Xapian

=head1 SYNOPIS

This class is used to manage texts coming out from the Xapian database
without hitting the SQL database, behaving like a Title Result object.

=cut

use Moo;
use DateTime;
use Scalar::Util qw/blessed/;
use Data::Dumper::Concise;

sub imported_methods {
    my @methods = (qw/
                     id
                     uri
                     full_uri
                     teaser
                     cover_uri
                     cover_small_uri
                     valid_cover
                     author
                     subtitle
                     title
                     lang
                     pubdate_epoch
                     site_id
                     text_qualification
                     pages_estimated
                     blob_container
                     feed_teaser
                     /);
    return @methods;
}

# not required because crashing on upgrade is silly
has [ __PACKAGE__->imported_methods ] => (is => 'ro', required => 0);

sub BUILDARGS {
    my ($self, @args) = @_;
    my %values;
    if (@args == 1 and
        blessed($args[0]) and
        $args[0]->isa('AmuseWikiFarm::Schema::Result::Title')) {
        my $title = shift @args;
        foreach my $m ($self->imported_methods) {
            $values{$m} = $title->$m;
        }
    }
    elsif (@args == 1 and ref($args[0]) eq 'HASH') {
        %values = %{$args[0]};
    }
    elsif (@args % 2 == 0) {
        %values = @args;
    }
    else {
        die "Need either a single AmuseWikiFarm::Schema::Result::Title object or paired arguments" . Dumper(\@args);
    }
    return \%values;
}

sub pubdate_locale {
    my ($self, $locale) = @_;
    $locale ||= 'en';
    my $dt = DateTime->from_epoch(epoch => $self->pubdate_epoch, locale => $locale);
    return $dt->format_cldr($dt->locale->date_format_medium);
}

sub is_deferred {
    my $self = shift;
    if ($self->pubdate_epoch > time()) {
        return 1;
    }
    else {
        return 0;
    }
}

sub is_published {
    return !shift->is_deferred;
}

# this should be stored in xapian
sub full_toc_uri {
    return shift->full_uri . '/toc';
}

sub clone_args {
    my $self = shift;
    my %values;
    foreach my $m ($self->imported_methods) {
        $values{$m} = $self->$m;
    }
    return \%values;
}

1;
