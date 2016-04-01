package AmuseWikiFarm::Utils::LexiconMigration;

use strict;
use warnings;
use Locale::PO;
use Path::Tiny;
use DateTime;
use DateTime::Format::RFC3339;
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
        mkdir $repo_dir unless -d $repo_dir;
        my $now = DateTime::Format::RFC3339->new->format_datetime(DateTime->now);
        foreach my $lang (keys %lex) {
            my $out = path($repo_dir, $lang . '.po')->stringify;
            push @created, $out;
            my @po;
            push @po, Locale::PO->new(-msgid => '',
                                      -msgstr => "Project-Id-Version: AmuseWiki Local 0.01\n"
                                      . "PO-Revision-Date: $now\n"
                                      . "Language: $lang\n"
                                      . "Last-Translator: Nobody <amuse\@localhost>\n"
                                      . "Language-Team: $lang <amuse\@localhost>\n"
                                      . "MIME-Version: 1.0\n"
                                      . "Content-Type: text/plain; charset=UTF-8\n"
                                      . "Content-Transfer-Encoding: 8bit\n");
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
