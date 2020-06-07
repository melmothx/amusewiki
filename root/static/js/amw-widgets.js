$(document).ready(function() {
    /* Turn links to external images into images */
    $("a.text-amuse-link").each(function() {
        var link = $(this);
        var target = link.attr('href');
        // check if there is surrounding text in the parent tag
        var surround = link.parent().text().replace(target, '');
        var check = surround.replace(/\s+/g, '');
        if (check) {
            return;
        }
        var youtube = /^https?:\/\/(www\.)?(youtube\.com|youtu.be)\/(watch\?.*v=|embed\/)?([a-zA-Z0-9_-]+)/;
        var vimeo = /^https?:\/\/(player\.)?vimeo\.com\/(video\/)?([0-9]+)/;
        var gmaps = /^https?:\/\/www\.google\.com\/maps\/embed\?(.+)/;
        var src;
        var match;
        if (match = youtube.exec(target)) {
            src = 'https://www.youtube.com/embed/' + match[4];
        }
        if (match = vimeo.exec(target)) {
            src = 'https://player.vimeo.com/video/' + match[3];
        }
        if (match = gmaps.exec(target)) {
            src = match[0];
        }
        if (src) {
            var div = $('<div>');
            div.attr('class', 'amw-video-embed-container');
            var out = $('<iframe>');
            out.attr('src', src);
            out.attr('frameborder', 0);
            div.append(out);
            link.parent().replaceWith(div);
        }
    });
});
