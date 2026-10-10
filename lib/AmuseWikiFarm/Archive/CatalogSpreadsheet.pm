package AmuseWikiFarm::Archive::CatalogSpreadsheet;

use utf8;
use strict;
use warnings;
use Moo;
use Types::Standard qw/Object Str/;
use Spreadsheet::ParseXLSX;
use Spreadsheet::ParseExcel;
use Text::CSV;
use File::BOM;
use Encode::Detect;

has site => (is => 'ro', required => 1, isa => Object);

sub parse_file {
    my ($self, $file) = @_;
}

1;
