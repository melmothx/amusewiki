package AmuseWikiFarm::Utils::LexiconMigration;

use strict;
use warnings;
use Locale::PO;
use Path::Tiny;
use DateTime;
use DateTime::Format::Strptime;
use Data::Dumper;
use AmuseWikiFarm::Utils::Amuse ();
sub convert {
    my ($lexicon, $repo_dir) = @_;
    return unless $lexicon;
    my %lex;
    my %templates;
    my %entries;
    foreach my $k (keys %$lexicon) {
        my $key = _filter($k);
        next unless length($k);
        # placeholder
        my $empty_po = Locale::PO->new(-msgid => $key, -msgstr => '');
        $templates{$empty_po->msgid} = $empty_po;
        if (my $entries = $lexicon->{$k}) {
          LANG:
            foreach my $lang (keys %$entries) {
                next LANG unless length($entries->{$lang});
                my $po = Locale::PO->new(-msgid => $key,
                                         -msgstr => _filter($entries->{$lang}));
                $lex{$lang}{$po->msgid} = $po;
            }
        }
    }
    # if a language is '*' in the lexicon.json, then use that for all known languages.
    if (my $wild_pos = delete $lex{'*'}) {
        my $langs = AmuseWikiFarm::Utils::Amuse::known_langs();
        foreach my $lang (keys %$langs) {
            foreach my $key (keys %$wild_pos) {
                $lex{$lang}{$key} ||= $wild_pos->{$key};
            }
        }
    }
    my @created;
    if ($repo_dir) {
        mkdir $repo_dir unless -d $repo_dir;
        my $now = DateTime::Format::Strptime->new(pattern => '%T %R%z')->format_datetime(DateTime->now);
      LANGUAGE:
        foreach my $lang (keys %lex) {
            if ($lang =~ m/\A([a-z]+)\z/) {
                $lang = $1;
            }
            else {
                warn "$lang doesn't look like a language";
                next LANGUAGE;
            }
            my $out = path($repo_dir, $lang . '.po')->stringify;
            if (-f $out) {
                my $existing;
                $existing = Locale::PO->load_file_asarray("$out", 'utf8');
                foreach my $po (@$existing) {
                    if (length(Locale::PO->dequote($po->msgstr))) {
                        # preserve
                        $lex{$lang}{$po->msgid} ||= $po;
                    }
                }
            }
            # now we hold the ones form lexicon.json in $lex{$lang}
            # and $existing here and we can fallback to the template.

            # now we have to merge them all.

            # and add the header if missing
            $lex{$lang}{'""'} ||= Locale::PO->new(-msgid => '',
                                       -msgstr => "Project-Id-Version: AmuseWiki Local 0.01\n"
                                      . "PO-Revision-Date: $now\n"
                                      . "Language: $lang\n"
                                      . "Last-Translator: Nobody <amuse\@localhost>\n"
                                      . "Language-Team: $lang <amuse\@localhost>\n"
                                      . "MIME-Version: 1.0\n"
                                      . "Content-Type: text/plain; charset=UTF-8\n"
                                      . "Content-Transfer-Encoding: 8bit\n");
            # print Dumper($lex{$lang});
            my %out = (%templates, %{$lex{$lang}});
            Locale::PO->save_file_fromhash($out, \%out, "utf8");
            push @created, $out;
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
