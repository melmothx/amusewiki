use Try::Tiny;
sub {
    my $schema = shift;
    try {
        my $rs = $schema->resultset('Site')->search(undef, { columns => 'id' });
        while (my $s = $rs->next) {
            foreach my $ctype ({
                                category_type => 'author',
                                active => 1,
                                priority => 0,
                                name_singular => 'Author',
                                name_plural => 'Authors',
                                site_id => $s->id,
                               },
                               {
                                category_type => 'topic',
                                active => 1,
                                priority => 1,
                                name_singular => 'Topic',
                                name_plural => 'Topics',
                                site_id => $s->id,
                               }) {
                $schema->resultset('SiteCategoryType')->find_or_create($ctype);
            }
        }
    } catch {
        print $_;
    }
}
