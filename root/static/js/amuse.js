
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
        $("div.table-of-contents").clone().appendTo("#pop-up-toc");
        $("div.table-of-contents").addClass("well well-lg");
    }
});

$(document).ready(function() {
    $(".footnotebody").click(function() {
        var source = $(this).attr('id');
        console.log(source);
        var target = source.replace(/fn/, '#fn_back');
        console.log(target);
        $(target).effect("highlight", {}, 10000);
    });
    $(".footnote").click(function() {
        var source = $(this).attr('id');
        console.log(source);
        var target = source.replace(/fn_back/, '#fn');
        console.log(target);
        $(target).effect("highlight", {}, 10000);
    });
});


