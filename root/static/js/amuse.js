
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
    if ($("div.table-of-contents").length > 0) {
        $(".hidden-when-no-toc").show();
        var clonedtoc = $("div.table-of-contents").clone();
        clonedtoc.show();
        clonedtoc.appendTo("#pop-up-toc");
        $("div.table-of-contents").addClass("well well-lg clearfix");
    }
    // with this div we signal that the teaser contains the whole text
    $("div.amw-teaser-no-ellipsis").closest('.amw-listing-item').find(".amw-read-more-link").remove();
});

$(document).ready(function() {
    $(".footnotebody").click(function() {
        var source = $(this).attr('id');
        var target = source.replace(/fn/, '#fn_back');
        $(target).effect("highlight", {}, 10000);
    });
    $(".footnote").click(function() {
        var source = $(this).attr('id');
        var target = source.replace(/fn_back/, '#fn');
        $(target).effect("highlight", {}, 10000);
    });
});


