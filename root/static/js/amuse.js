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
        $("div.table-of-contents").addClass("col-md-3");
        $("div.table-of-contents").addClass("well");
        $("div#thework").addClass("col-md-9");
    }
    else {
        $("div#thework").addClass("col-md-12");
    }
});
