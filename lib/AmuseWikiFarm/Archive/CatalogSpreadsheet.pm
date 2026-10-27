package AmuseWikiFarm::Archive::CatalogSpreadsheet;

use utf8;
use strict;
use warnings;
use Moo;
use Types::Standard qw/Object Str/;
use Spreadsheet::ParseXLSX;
use Spreadsheet::ParseExcel;
use Text::CSV;

has site => (is => 'ro', required => 1, isa => Object);

sub parse_file {
    my ($self, $file) = @_;
    return [];
}

sub get_records {
    my ($self, $file) = @_;
    my $out;
    if ($file =~ m/\.csv\z/i) {
        $out = $self->_get_records_csv($file);
    }
    elsif ($file =~ m/\.xls\z/i) {
        $out = $self->_get_records_excel(Spreadsheet::ParseExcel->new, $file);
    }
    elsif ($file =~ m/\.xlsx\z/i) {
        $out = $self->_get_records_excel(Spreadsheet::ParseXLSX->new, $file);
    }
    return $out;
}

sub _get_records_csv {
    my ($self, $file) = @_;
    # first see if there's a BOM
    open (my $fh, '<:encoding(UTF-8)', $file) or die "Cannot open $file";
    # read the first line and reset the position
    my $first = <$fh>;
    seek $fh, 0, 0;
    # strip the BOM
    if ($first =~ /\A\x{feff}/) {
        seek $fh, 3, 0;
    }
    my $csv = Text::CSV->new({
                              binary => 1,
                              auto_diag => 2,
                             });
    my $header = $csv->getline($fh);
    $csv->column_names(@$header);
    my @records;
    while (my $r = $csv->getline_hr($fh)) {
        push @records, $r;
    }
    close $fh;
    return \@records;
}

sub _get_records_excel {
    my ($self, $parser, $file) = @_;
    my $wb = $parser->parse($file) or die "Cannot parse $file";
    my @records;
    foreach my $ws ($wb->worksheets) {
        my ($row_min, $row_max) = $ws->row_range;
        my ($col_min, $col_max) = $ws->col_range;
        my @header;
        foreach my $col ($col_min .. $col_max) {
            if (my $cell = $ws->get_cell($row_min, $col)) {
                push @header, $cell->value;
            }
            else {
                push @header, '';
            }
        }
        next unless @header;
        $row_min++;
        foreach my $row ($row_min .. $row_max) {
            my %rec;
            my $i = 0;
            foreach my $col ($col_min .. $col_max) {
                if (my $cell = $ws->get_cell($row, $col)) {
                    $rec{$header[$i]} = $cell->value;
                }
                else {
                    $rec{$header[$i]} = '';
                }
                $i++;
            }
            push @records, \%rec;
        }
    }
    return \@records;
}

1;
