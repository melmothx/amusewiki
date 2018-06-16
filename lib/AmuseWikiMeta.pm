package AmuseWikiMeta;
use 5.010001;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.90075;

# no configuration, no session, no users. It's just a search

use Catalyst;

extends 'Catalyst';
our $VERSION = 1;
use AmuseWikiFarm::Log::Contextual;

__PACKAGE__->config(
                    name => 'AmuseWikiMeta',
                    # Disable deprecated behavior needed by old applications
                    disable_component_resolution_regex_fallback => 1,
                    enable_catalyst_header => 1, # Send X-Catalyst header
                    encoding => 'UTF-8',
                    default_view => 'JSON',
                   );

__PACKAGE__->config('Model::DB' => { config_file => $ENV{AMW_META_CONFIG_FILE} });

__PACKAGE__->setup();

1;
