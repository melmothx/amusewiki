package AmuseWikiFarm::Archive::OAI::ORE;

use utf8;
use strict;
use warnings;

use Moo;
use Types::Standard qw/Object Str InstanceOf CodeRef/;
use AmuseWikiFarm::Log::Contextual;
use XML::Writer;
use Data::Dumper::Concise;

has text => (is => 'ro', isa => Object, required => 1);
has uri_maker => (is => 'ro', isa => CodeRef, default => sub { sub { return shift } });

sub as_rdf_xml {
    my $self = shift;
    my $text = $self->text;
    my $data = [
                'rdf:RDF' => [
                              'xmlns:rdf' => "http://www.w3.org/1999/02/22-rdf-syntax-ns#" ,
                              'xmlns:ore' => "http://www.openarchives.org/ore/terms/",
                             ],
                [
                 [ 'rdf:Description' => [ 'rdf:about', $self->uri_maker->($text->full_ore_rdf_uri) ],
                   [
                    [ 'ore:describes' => [ 'rdf:resource' => $self->uri_maker->($text->full_ore_aggregation_uri) ], [] ],
                   ]
                 ],
                ]
               ];
    my $w = XML::Writer->new(OUTPUT => "self",
                             DATA_INDENT => 2,
                             ENCODING => "UTF-8",
                             DATA_MODE => 1);
    $w->xmlDecl;
    AmuseWikiFarm::Utils::XML::generate_xml($w, @$data);
    $w->end;
    return "$w";
}

1;
