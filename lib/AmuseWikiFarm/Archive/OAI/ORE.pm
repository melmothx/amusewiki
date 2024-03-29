package AmuseWikiFarm::Archive::OAI::ORE;

use utf8;
use strict;
use warnings;

use Moo;
use Types::Standard qw/Object Str InstanceOf CodeRef/;
use AmuseWikiFarm::Log::Contextual;
use XML::Writer;
use Data::Dumper::Concise;
use DateTime;

has text => (is => 'ro', isa => Object, required => 1);
has uri_maker => (is => 'ro', isa => CodeRef, default => sub { sub { return shift } });

sub as_rdf_xml {
    my $self = shift;
    my $text = $self->text;
    my $site = $text->site;
    my $created = $text->pubdate->iso8601 . 'Z';
    my $updated = $text->f_timestamp->iso8601 . 'Z';
    my $full_uri = $text->full_uri;
    my @canonical_dc;
    my @aggregated_dcs;
    my @aggregated_urls;
    foreach my $pmh ($text->oai_pmh_records->not_deleted->all) {
        if (my @dc = @{ $pmh->dublin_core_record || [] }) {
            my $datestamp = $pmh->zulu_datestamp;
            push @dc, [
                       'dcterms:created',
                       [ 'rdf:datatype' => "http://www.w3.org/2001/XMLSchema#dateTime" ],
                       $datestamp,
                      ];
            push @dc, [
                       'dcterms:modified',
                       [ 'rdf:datatype' => "http://www.w3.org/2001/XMLSchema#dateTime" ],
                       $datestamp,
                      ];
            if ($pmh->identifier eq $full_uri) {
                @canonical_dc = @dc;
            }
            push @aggregated_dcs,
              [ 'rdf:Description' => [ 'rdf:about', $self->uri_maker->($pmh->identifier) ], \@dc ];
            push @aggregated_urls,
              [ 'ore:aggregates' => [ 'rdf:resource', $self->uri_maker->($pmh->identifier) ], undef ];
        }
    }
    push @canonical_dc, @aggregated_urls;
    my $data = [
                'rdf:RDF' => [
                              'xmlns:rdf' => "http://www.w3.org/1999/02/22-rdf-syntax-ns#" ,
                              'xmlns:ore' => "http://www.openarchives.org/ore/terms/",
                              'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
                              'xmlns:dcterms' => "http://purl.org/dc/terms/",
                              'xmlns:foaf' => "http://xmlns.com/foaf/0.1/",
                              'xmlns:rdfs' => "http://www.w3.org/2000/01/rdf-schema#",
                             ],
                [
                 [ 'rdf:Description' => [ 'rdf:about', $self->uri_maker->($text->full_ore_rdf_uri) ],
                   [
                    [ 'ore:describes' => [ 'rdf:resource' => $self->uri_maker->($text->full_ore_aggregation_uri) ], undef],
                    [ 'dcterms:creator' => [ 'rdf:parseType' => "Resource" ],
                      [
                       [ 'foaf:name' => $site->sitename || $site->canonical ],
                       [ 'foaf:page' => [ 'rdf:resource' => $site->canonical_url ], undef ],
                      ],
                    ],
                    [ 'dcterms:created' => [ 'rdf:datatype' => "http://www.w3.org/2001/XMLSchema#dateTime" ], $created ],
                    [ 'dcterms:modified' => [ 'rdf:datatype' => "http://www.w3.org/2001/XMLSchema#dateTime" ], $updated ],
                   ],
                 ],

                 [ 'rdf:Description' => [ 'rdf:about', $self->uri_maker->($text->full_ore_aggregation_uri) ],
                   \@canonical_dc,
                 ],
                 @aggregated_dcs,
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
