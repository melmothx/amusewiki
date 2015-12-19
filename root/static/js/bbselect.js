$(document).ready(function () {
    $("#book-builder-add-text-partial input:checkbox").click(function() {
        var level = $(this).data("bb-level");
        if (level && $(this).prop("checked")) {
            // console.log("Level " + level + " value: " + $(this).attr("value"));
            var enable = true;
            $(this).parent('td').parent('tr').nextAll()
                .find("input:checkbox").each(function() {
                    var inner = $(this).data("bb-level");
                    if (enable && inner && inner > level) {
                        $(this).prop("checked", true);
                    }
                    else {
                        enable = false;
                    }
                });
        }
    });
});

