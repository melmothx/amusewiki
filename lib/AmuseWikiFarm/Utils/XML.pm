package AmuseWikiFarm::Utils::XML;

use utf8;
use strict;
use warnings;
use Data::Dumper::Concise;

=head1 SYNOPSIS


    my $w = XML::Writer->new(OUTPUT => "self",
                             DATA_INDENT => 2,
                             ENCODING => "UTF-8",
                             DATA_MODE => 1);
    $w->xmlDecl;
    generate_xml($w, @data);
    $w->end;
=cut

sub generate_xml {
    my ($w, $name, @args) = @_;
    my ($attrs, $value);
    if (@args == 0) {
        # all undef
    }
    elsif (@args == 1) {
        $attrs = [];
        $value = $args[0];
    }
    elsif (@args == 2) {
        ($attrs, $value) = @args;
    }
    else {
        die "Bad usage" . Dumper(\@_);
    }
    if (defined $value) {
        $w->startTag($name, @$attrs);
        if (ref($value) eq 'ARRAY') {
            foreach my $v (@$value) {
                # recursive call
                generate_xml($w, @$v)
            }
        }
        elsif (ref($value)) {
            die "Not an array ref! " . Dumper($value);
        }
        else {
            $w->characters($value);
        }
        $w->endTag;
    }
    else {
        $w->emptyTag($name, @$attrs);
    }
}

1;
