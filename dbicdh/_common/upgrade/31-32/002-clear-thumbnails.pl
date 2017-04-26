sub {
    require File::Path;
    my $dir = 'thumbnails';
    if (-d $dir) {
        File::Path::remove_tree($dir, { verbose => 1 });
    }
}
