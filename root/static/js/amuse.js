$(document).ready(function(){
    $("p").each(function(i) {
        if(!$(this).attr('class')) {
            $(this).addClass("text-justify");
        }
    });
    $("div#thework table").addClass("table table-bordered");
    $(".center p").removeClass("text-justify").addClass("text-center");
    $(".right p").removeClass("text-justify").addClass("text-right");
    if ($("div.table-of-contents").length > 0) {
        $(".hidden-when-no-toc").show();
        $("div.table-of-contents").clone().appendTo("#pop-up-toc");
        $("div.table-of-contents").addClass("well well-lg");
    }
    else {
        $("div#thework").addClass("col-md-12");
    }
});
