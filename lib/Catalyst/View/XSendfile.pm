package Catalyst::View::XSendfile;
use Moose;
use namespace::autoclean;
 
extends 'Catalyst::View';
 
sub process {
    my ($self, $c) = @_;
    my $file = $c->stash->{serve_static_file};
    unless ($file and -f $file) {
        $c->log->error("$file is not a file!");
        return;
    }
    $c->log->debug("Serving file $file");
    my ($header, $set) = $self->render($c, $file);
    if ($header && $set) {
        $c->response->header($header, $set);
        $c->response->body('');
    }
    else {
        $c->serve_static_file($file);
    }
}

sub render {
    my ($self, $c, $path) = @_;
    die "This shouldn't happen" unless $path;

    my $type = $c->request->header('X-Sendfile-Type');

    if ($type && !$c->response->header($type)) {
        if ($type eq 'X-Accel-Redirect') {
            if (my $url = $self->_map_accel_path($c, $path)) {
                return ($type, $url);
            }
        }
        elsif ($type eq 'X-Sendfile' or $type eq 'X-Lighttpd-Send-File') {
            return ($type, $path)
        }
    }
    return;
}
 
sub _map_accel_path {
    my ($self, $c, $path) = @_;
    if (my $mapping = $c->request->header('X-Accel-Mapping')) {
        my($internal, $external) = split /=/, $mapping, 2;
        $c->log->debug("Replacing $internal with $external");
        $path =~ s!^\Q$internal\E!$external!i;
        return $path;
    }
    return;
}
 
1;
