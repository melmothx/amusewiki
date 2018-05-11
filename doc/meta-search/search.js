function get_search_response() {
    $.post('/search', $('#search-page-form').serialize(), function (data) {
        render_template(data);
    });
}

function render_template(data) {
    console.log(data);
    var template = $('#template').html();
    var rendered = Mustache.render(template, data);
    $('#results').html(rendered);
}

$(document).ready(function () {
    get_search_response();
});
