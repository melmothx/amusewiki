package AmuseWikiFarm;
use 5.010001;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#                 also activated by -d, so useless to have it here
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

#    MemoryUsage: show some stats. 2014-02-1 figures
# .------+------+------+------+------+------+------+------+------+------.
# | vsz  | del- | rss  | del- | sha- | del- | code | del- | data | del- |
# |      | ta   |      | ta   | red  | ta   |      | ta   |      | ta   |
# +------+------+------+------+------+------+------+------+------+------+
# | 151M |      | 60M  |      | 3.0M |      | 8.0K |      | 57M  |      |
# | 151M |      | 60M  |      | 3.0M |      | 8.0K |      | 57M  |      |
# | 161M | 9.9M | 64M  | 3.6M | 3.5M | 544K | 8.0K |      | 60M  | 3.0M |
# | 161M |      | 64M  |      | 3.5M |      | 8.0K |      | 60M  |      |
# | 167M | 5.8M | 68M  | 4.0M | 3.9M | 460K | 8.0K |      | 64M  | 3.3M |
# | 167M |      | 68M  |      | 3.9M |      | 8.0K |      | 64M  |      |
# | 169M | 2.0M | 70M  | 1.8M | 4.0M | 40K  | 8.0K |      | 66M  | 2.0M |
# | 169M |      | 70M  |      | 4.0M |      | 8.0K |      | 66M  |      |
# | 169M |      | 70M  |      | 4.0M |      | 8.0K |      | 66M  |      |
# | 169M |      | 70M  |      | 4.0M |      | 8.0K |      | 66M  |      |
# '------+------+------+------+------+------+------+------+------+------'

# Memory Usage: stats 2014-03-26
# +------+------+------+------+------+------+------+------+------+------.
# | vsz  | del- | rss  | del- | sha- | del- | code | del- | data | del- |
# |      | ta   |      | ta   | red  | ta   |      | ta   |      | ta   |
# +------+------+------+------+------+------+------+------+------+------+
# | 207M |      | 86M  |      | 4.6M |      | 8.0K |      | 81M  |      |
# | 207M |      | 86M  |      | 4.6M |      | 8.0K |      | 81M  |      |
# | 207M |      | 86M  |      | 4.6M |      | 8.0K |      | 81M  |      |
# | 207M |      | 86M  |      | 4.6M |      | 8.0K |      | 81M  |      |
# | 207M |      | 86M  |      | 4.6M |      | 8.0K |      | 81M  |      |
# | 207M |      | 86M  |      | 4.6M |      | 8.0K |      | 81M  |      |
# | 207M |      | 86M  |      | 4.6M |      | 8.0K |      | 81M  |      |
# | 207M |      | 86M  |      | 4.6M |      | 8.0K |      | 81M  |      |
# | 207M |      | 86M  |      | 4.6M |      | 8.0K |      | 81M  |      |
# +------+------+------+------+------+------+------+------+------+------'

use Catalyst
  'I18N',
#   'Static::Simple',
  '-Log=warn,fatal,error',
#  'MemoryUsage',
  'Authentication',
  'Authorization::Roles',
  'Session',
  'Session::Store::File',
  'Session::State::Cookie';



extends 'Catalyst';

our $VERSION = '0.992';

# Configure the application.
#
# Note that settings in amusewikifarm.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'AmuseWikiFarm',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 1, # Send X-Catalyst header
    encoding => 'UTF-8',
    default_view => 'HTML',
);


__PACKAGE__->config(
    'View::HTML' => {
        INCLUDE_PATH => [
            __PACKAGE__->path_to('root', 'src'),
           ],
       },
   );

# like above, but without the wrapper, so you get no layout with this.
# Used for sending email and such.

__PACKAGE__->config(
    'View::TT' => {
        INCLUDE_PATH => [
            __PACKAGE__->path_to('root', 'src'),
           ],
       },
   );


__PACKAGE__->config(
    'Plugin::Static::Simple' => {
        mime_types => {
            muse => 'text/plain',
            epub => 'application/epub+zip',
        },
    },
);


# Configure SimpleDB Authentication
__PACKAGE__->config(
    'Plugin::Authentication' => {
        default => {
            class           => 'SimpleDB',
            user_model      => 'DB::User',
            password_type   => 'self_check',
        },
    },
);

# Middlewares

__PACKAGE__->config(
    psgi_middleware => [
        'XSendfile',
        'ConditionalGET',
        ETag => { check_last_modified_header => 1 },
       ],
);

__PACKAGE__->config(
    'Plugin::Session' => {
        expires => 60 * 60 * 24 * 30, # 30 days for expiration
        verify_address => 1,
    },
);

# Start the application
__PACKAGE__->setup();

=encoding utf8

=head1 NAME

AmuseWikiFarm - Catalyst based application

=head1 SYNOPSIS

    script/amusewikifarm_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<AmuseWikiFarm::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# Local Variables:
# cperl-indent-parens-as-block: t
# End:

1;
