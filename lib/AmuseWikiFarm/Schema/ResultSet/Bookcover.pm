package AmuseWikiFarm::Schema::ResultSet::Bookcover;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

__PACKAGE__->load_components('Helper::ResultSet::Shortcut::HRI');

use DateTime;

sub create_and_initalize {
    my ($self, $values) = @_;
    return $self->create($values)->initialize;
}

sub expired {
    my $self = shift;
    my $dtf = $self->result_source->schema->storage->datetime_parser;
    my $yesterday = DateTime->now(time_zone => 'UTC')->subtract(days => 1);
    $self->search({
                   user_id => undef,
                   created => { '<' => $dtf->format_datetime($yesterday) }
                  });
}

sub purge_old_bookcovers {
    my $self = shift;
    my $total = 0;
    foreach my $bc ($self->expired->all) {
        $bc->delete;
        $total++;
    }
    return $total;
}

1;
