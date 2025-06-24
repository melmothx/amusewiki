package AmuseWikiFarm::Utils::Footnotes;

use utf8;
use strict;
use warnings;
use Moo;
use Types::Standard qw/Str/;
use Text::Amuse::Preprocessor::Parser;
use Data::Dumper::Concise;

has muse_body => (is => 'ro', isa => Str, required => 1);

sub report {
    my ($self) = @_;
    my @chunks = map { $_->{string} }
      grep { $_->{type} eq 'text' }
      Text::Amuse::Preprocessor::Parser::parse_text($self->muse_body);
    my %out = (
               footnotes_primary => [],
               footnotes_secondary => [],
               body_primary => [],
               body_secondary => [],
              );

    my @body;
    foreach my $piece (@chunks) {
        if ($piece =~ m/^(\[[0-9]+\])\x{20}+(.{1,20})/) {
            push @{$out{footnotes_primary}}, {
                                              fn => $1,
                                              before => '',
                                              after => $2,
                                             };
        }
        elsif ($piece =~ m/^(\{[0-9]+\})\x{20}+(.{1,20})/) {
            push @{$out{footnotes_secondary}}, {
                                                fn => $1,
                                                before => '',
                                                after => $2,
                                               };
        }
        else {
            push @body, $piece;
        }
    }
    foreach my $type (qw/primary secondary/) {
        my $re = $type eq 'primary' ? qr{\[[0-9]+\]} : qr{\{[0-9]+\}};
        my $count = scalar @{ $out{"footnotes_$type"} };
        my $list = $out{"body_$type"};
        foreach my $par (@body) {
            my @chunks = split(/($re)/, $par);
            for (my $i = 0; $i < @chunks; $i++) {
                my $chunk = $chunks[$i];
                if ($chunk =~ m/\A$re\z/) {
                    if ($chunk =~ m/(?:\[|\{)([0-9]+)(?:\]|})/) {
                        my $number = $1;
                        # skip false positive like [1978] if there are just a few footnotes
                        if ($number < ($count + 100)) {
                            my $info = {
                                        fn => $chunk,
                                        before => '',
                                        after => '',
                                       };
                            if ($i > 0) {
                                my $before = $chunks[$i - 1];
                                if ($before and $before =~ m/(.{0,20})\z/) {
                                    $info->{before} = $1;
                                }
                            }
                            if (($i + 1) < @chunks) {
                                my $after =  $chunks[$i + 1];
                                if ($after and $after =~ m/\A(.{0,20})/) {
                                    $info->{after} = $1;
                                }
                            }
                            push @$list, $info;
                        }
                    }
                }
            }
        }
    }
    return \%out;
}

sub report_as_list {
    my $self = shift;
    my $info = $self->report;
    my %out;
    foreach my $type (qw/primary secondary/) {
        my @footnotes = @{$info->{"footnotes_$type"}};
        my @body = @{$info->{"body_$type"}};
        my @list;
        my %empty = (
                     after => '',
                     before => '',
                     fn => '',
                    );
        while (@footnotes or @body) {
            my $fn = @footnotes ? shift(@footnotes) : { %empty };
            my $ctx = @body ? shift(@body) : { %empty };
            push @list, {
                         footnote => $fn,
                         body => $ctx,
                        };
        }
        $out{$type} = \@list;
    }
    return \%out;
}


1;
