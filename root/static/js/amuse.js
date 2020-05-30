function use_named_toc () {
    if (!$('#js-site-settings').data('use-named-toc')) {
        return;
    }
    var toc_entries = Object.create(null);

    var regexp = "[^"
        + "\\u0030-\\u0039" // 0-9
        + "\\u0041-\\u005A" // A-Z
        + "\\u0061-\\u007A" // a-z
        + "\\u00C0-\\u00D6" // À Ö
        + "\\u00D8-\\u00F6" // Ø ö
        + "\\u00F8-\\u02B8" // until ʸ
        + "\\u0391-\\u03A1" // greek uppercase
        + "\\u03A3-\\u03F5" // greek lower
        + "\\u03F7-\\u0481" // cryrillic  lower
        + "\\u048A-\\u052F" // cyrillic
        + "]";
    // console.log(regexp);
    var all_but_chars = new RegExp(regexp, 'g');
    $('.tableofcontentline').each(function() {
        var el = $(this);
        var text = el.text();
        var anchor = el.find('a');
        var old_id;
        var new_id = text.replace(all_but_chars, '-')
            .replace(/^-+/, '')
            .replace(/-+$/, '')
            .replace(/--+/, '-');
        var base_id = new_id;
        var count = 1;
        while (toc_entries[new_id]) {
            new_id = base_id + '-' + count;
            count++;
        }
        if (toc_entries[new_id]) {
            console.log(new_id + ' is already taken');
        }
        else {
            toc_entries[new_id] = 1;
        }
        if (anchor) {
            old_id = anchor.attr('href');
            if (old_id && !old_id.match(/^#text-amuse-label/)) {
                /* console.log(new_id + ' => ' + old_id); */
                $(old_id).prepend($('<span>', { id: 'amw-toc-' + new_id }));
                anchor.attr('href', '#amw-toc-' + new_id);
            }
        }
    });
    console.log(toc_entries);
}

$(document).ready(function(){
    $("p").each(function(i) {
        if(!$(this).attr('class')) {
            $(this).addClass("text-justify");
        }
    });
    $("div#thework table").addClass("table table-bordered");
    /* preview as well */
    $("div#htmltextbody table").addClass("table table-bordered");
    $(".center p").removeClass("text-justify").addClass("text-center");
    $(".right p").removeClass("text-justify").addClass("text-right");
    var has_toc = $("div.table-of-contents").length;
    var has_cover = $("#text-cover-img").length;
    if (has_toc > 0) {
        $('.tableofcontentline').each(function() {
            var el = $(this);
            var anchor = el.find('a');
            /* console.log(el.text() + anchor.length); */
            if (anchor.length) {
                $('#amw-top-nav-toc').append($('<li>').append($('<a>', { "href": anchor.attr('href') })
                                                              .text(el.text())));
            }
        })

        $(".hidden-when-no-toc").show();
        var originaltoc = $("div.table-of-contents").remove();
        originaltoc.addClass("well well-lg");
        var toc = $('<div>', { "class": "row" });
        if (has_cover) {
            toc.append($('<div>', { "class": "col-sm-6" }).append(originaltoc));
            var img = $('#text-cover-img').attr('src');
            $('#text-cover-img-container').remove();
            toc.append($('<div>', { "class": "col-sm-6" })
                       .append($('<img>', { "src": img,
                                            "class": "img img-responsive mb-1",
                                            "alt": img })));
        }
        else {
            toc.append($('<div>', { "class": "col-sm-12" }).append(originaltoc));
        }
        toc.insertAfter('#amw-blog-container-prepended');
    }

    // with this div we signal that the teaser contains the whole text
    $("div.amw-teaser-no-ellipsis").closest('.amw-listing-item').find(".amw-read-more-link").remove();
    // globally enable tooltips
    $('[data-toggle="tooltip"]').tooltip();
});

