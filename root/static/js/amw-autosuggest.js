$('input.search-autocomplete').autocomplete({
    source: function(req, res) {
        $.ajax({
            url: "/search",
            dataType: "json",
            data: {
                query: req.term,
                partial: 1,
                fmt: "json"
            },
            success: function(data) {
                res($.map(data, function(item) {
                    var label = $($.parseHTML(item.title)).text();
                    if (item.author) {
                        label = label + ' - ' + $($.parseHTML(item.author)).text();
                    }
                    return {
                        label: label,
                        value: '',
                        link: item.url
                    };
                }));
            }
        });
    },
    minLength: 2,
    delay: 200,
    select: function(event, ui) {
        window.location.href = ui.item.link;
    },
    position: { my: "left top", at: "left bottom" }
});
