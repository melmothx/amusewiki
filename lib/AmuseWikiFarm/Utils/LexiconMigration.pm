package AmuseWikiFarm::Utils::LexiconMigration;

use strict;
use warnings;
use Locale::PO;
use Path::Tiny;
sub convert {
    my ($lexicon, $repo_dir) = @_;
    my %lex;
    if ($lexicon) {
        foreach my $k (keys %$lexicon) {
            if (my $entries = $lexicon->{$k}) {
                foreach my $lang (keys %$entries) {
                    $lex{$lang}{$k} = $entries->{$lang};
                }
            }
        }
    }
    my @created;
    if ($repo_dir) {
        foreach my $lang (keys %lex) {
            my $out = path($repo_dir, $lang . '.po')->stringify;
            push @created, $out;
            my @po;
            foreach my $k (keys %{$lex{$lang}}) {
                my $po_entry = Locale::PO->new(-msgid => _filter($k),
                                               -msgstr => _filter($lex{$lang}{$k}));
                push @po, $po_entry;
            }
            Locale::PO->save_file_fromarray($out, \@po, "utf8");
        }
    }
    return @created;
}

sub _filter {
    my $str = shift;
    return '' unless defined $str;
    $str =~ s/\[_([0-9]+)\]/%$1/g;
    return $str;
}

1;
