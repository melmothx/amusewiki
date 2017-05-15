$(document).ready(function() {
    /* Turn links to external images into images */
    $("a.text-amuse-link").each(function() {
        var link = $(this);
        var linkre = /^https?:\/\/.+\/.+\.(jpe?g|png|gif)$/;
        var target = link.attr('href');
        if (target.match(linkre)) {
            var text = link.text();
            var anchor = $('<a>');
            var img = $('<img>');
            anchor.attr('class', 'text-amuse-remote-image');
            anchor.attr('href', target);
            img.attr('class', 'embedimg');
            img.attr('alt', text);
            img.attr('src', target);
            anchor.append(img);
            link.replaceWith(anchor);
            // console.log(target + text );
        }
        // Here eventually we could handle also youtube and stuff as well.
    });
});
