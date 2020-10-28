package AmuseWikiFarm;
use 5.010001;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.90080;

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

# Memory Usage: stats for /authors 2014-12-07, version 1.03
#
# +------+------+------+------+------+------+------+------+------+------.
# | vsz  | del- | rss  | del- | sha- | del- | code | del- | data | del- |
# |      | ta   |      | ta   | red  | ta   |      | ta   |      | ta   |
# +------+------+------+------+------+------+------+------+------+------+
# | 438M |      | 131M |      | 7.9M |      | 1.6M |      | 123M |      |
# | 438M |      | 131M |      | 7.9M |      | 1.6M |      | 123M |      |
# | 438M |      | 131M |      | 7.9M |      | 1.6M |      | 123M |      |
# | 438M |      | 131M |      | 7.9M |      | 1.6M |      | 123M |      |
# | 438M |      | 131M |      | 7.9M |      | 1.6M |      | 123M |      |
# | 438M |      | 131M |      | 7.9M |      | 1.6M |      | 123M |      |
# | 438M |      | 131M |      | 7.9M |      | 1.6M |      | 123M |      |
# | 438M |      | 131M |      | 7.9M |      | 1.6M |      | 123M |      |
# | 438M |      | 131M |      | 7.9M |      | 1.6M |      | 123M |      |
# | 438M |      | 131M |      | 7.9M |      | 1.6M |      | 123M |      |
# | 438M |      | 131M |      | 7.9M |      | 1.6M |      | 123M |      |
# | 438M |      | 131M |      | 7.9M |      | 1.6M |      | 123M |      |
# | 438M |      | 131M |      | 7.9M |      | 1.6M |      | 123M |      |
# | 438M |      | 131M |      | 7.9M |      | 1.6M |      | 123M |      |
# | 438M |      | 131M |      | 7.9M |      | 1.6M |      | 123M |      |
# +------+------+------+------+------+------+------+------+------+------'

use Catalyst (
  'ConfigLoader',
  '+CatalystX::AmuseWiki::I18N',
#  'MemoryUsage',
  'Session',
  '+CatalystX::Session::Store::AMW',
#  'Session::Store::FastMmap',
  'Session::State::Cookie',
  'Authentication',
  'Authorization::Roles',
);



extends 'Catalyst';

our $VERSION = '2.500';

use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Log::Contextual::App;
use File::Spec;

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
        # not sure this is really a good idea, found some weirdnesses, like
        # stale i18n
        # COMPILE_DIR => __PACKAGE__->path_to(qw/opt cache tt/),
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
        qw/XSendfile
           ConditionalGET
           WeakETag/
       ],
);

__PACKAGE__->config(
    'Plugin::Session' => {
        expires => 60 * 60 * 24 * 7 * 4, # 1 month for expiration
        verify_address => 0, # let's keep the session across router's reboots
        verify_user_agent => 0, # otherwise we loose the session on each browser upgrade
        # the following settings are unused, kept for the migration
        cache_size => '100m',
        unlink_on_exit => 0,
        storage => File::Spec->rel2abs(File::Spec->catfile(qw/opt cache fastmmap/)),
    },
);

# basically here we do the same thing as in
# AmuseWikiFarm::Log::Contextual, but we intercept all the logs
# generated by catalyst and plugins.

__PACKAGE__->log(AmuseWikiFarm::Log::Contextual::App->new);

sub handle_unicode_encoding_exception {
    my ($c, $debug) = @_;
    Dlog_info {
        "Handled unicode exception $_"
    } [ $debug, $c->request->env ];
    # here we stash this flag, and first thing we check it in the root
    # controller. This is a bit suboptimal, and not so nice, but it
    # appears to be the safest way without patching Catalyst.
    $c->stash->{BAD_UNICODE_DATA} = 1;
    return 'BAD_UNICODE_DATA';
}

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

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# Local Variables:
# cperl-indent-parens-as-block: t
# End:

1;
