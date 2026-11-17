package AmuseWikiFarm::Archive::CatalogSpreadsheet;

use utf8;
use strict;
use warnings;
use Moo;
use Types::Standard qw/Object Str ArrayRef CodeRef/;
use Spreadsheet::ParseXLSX;
use Spreadsheet::ParseExcel;
use Text::CSV;
use Data::Dumper::Concise;
use AmuseWikiFarm::Utils::Amuse;
use AmuseWikiFarm::Utils::Paths;

has site => (is => 'ro', required => 1, isa => Object);
has specification => (is => 'ro', required => 0, isa => ArrayRef);
has logger => (is => 'ro', isa => CodeRef, default => sub { sub {} });

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
    my $specification = $self->specification;
    my $site_specification = $self->site->spreadsheet_catalog_specification;
    unless ($specification) {
        $specification = $self->site->spreadsheet_catalog_specification;
        $_->{column} = $_->{name} for @$specification;
    }
    my %map;
    foreach my $spec (@$specification) {
        if (my $mapped = $spec->{column}) {
            $map{$mapped} ||= [];
            push @{$map{$mapped}}, $spec->{name};
        }
    }
    my %sitesep = map { $_->{name} => $_->{separator} } grep { $_->{separator} } @$site_specification;
    my %sheetsep = map { $_->{name} => $_->{separator} } grep { $_->{separator} } @$specification;
    my @converted;
    foreach my $r (@$out) {
        my %row;
        foreach my $mapped (keys %map) {
            foreach my $field (@{$map{$mapped}}) {
                my $value = $r->{$mapped} // '';
                if ($sheetsep{$field} and $sitesep{$field} and $sheetsep{$field} ne $sitesep{$field}) {
                    my $sep = $sheetsep{$field};
                    $value = join("$sitesep{$field} ", split(/\s*\Q$sep\E\s*/, $value))
                }
                $row{$field} = $value;
            }
        }
        if (defined $row{title} and $row{title} =~ m/\w/) {
            push @converted, \%row;
        }
    }
    $out = \@converted;
    return $out;
}

sub _get_records_csv {
    my ($self, $file) = @_;
    # first see if there's a BOM
    open (my $fh, '<:encoding(UTF-8)', "$file") or die "Cannot open $file";
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
    my $wb = $parser->parse("$file") or die "Cannot parse $file";
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

sub create_revisions_from_file {
    my ($self, $file, $opts) = @_;
    $opts ||= {};
    my $logger = $opts->{logger} || sub {};
    my @revs;
    my $now = DateTime->now;
    my $site = $self->site;
    foreach my $rec (@{$self->get_records($file)}) {
        my ($rev, $error) = $site->create_new_text({
                                                    %$rec,
                                                    no_muse_body => 1,
                                                   }, 'text');
        if ($rev) {
            $rev->commit_version("CSV Import", $opts->{username});
            push @revs, $rev->id;
        }
        else {
            $logger->("Failure importing record: $error " . Dumper($rec))
        }
    }
    my $site_id = $site->id;
    return $site->bulk_jobs->create({
                                     task => 'catalog_upload',
                                     created => $now,
                                     status => (scalar(@revs) ? 'active' : 'completed'),
                                     completed => (scalar(@revs) ? undef : $now),
                                     username => $opts->{username},
                                     jobs => [
                                              map {
                                                  +{
                                                    payload => AmuseWikiFarm::Utils::Amuse::to_json({ id => $_ }),
                                                    site_id => $site_id,
                                                    task => 'publish',
                                                    status => 'pending',
                                                    created => $now,
                                                    priority => 18,
                                                    username => $opts->{username},
                                                   }
                                              }
                                              @revs
                                             ],
                                    });
}

1;
