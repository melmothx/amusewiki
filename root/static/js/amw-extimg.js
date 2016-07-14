$(document).ready(function() {
    /* Turn links to external images into images */
    $("a.text-amuse-link").each(function() {
        var link = $(this);
        var linkre = /^https?:\/\/.+\/.+\.(jpe?g|png|gif)$/;
        var target = link.attr('href');
        if (target.match(linkre)) {
            var text = link.text();
            link.replaceWith('<a class="text-amuse-remote-image" href="' +
                             target +
                             '"><img class="embedimg" src="' +
                             target +
                             '" alt="' + text + '" /></a>');
        }
        // Here eventually we could handle also youtube and stuff as well.
    });
});
