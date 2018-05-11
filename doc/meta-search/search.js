function get_search_response() {
    var params = $('#search-page-form').serialize();
    $.get('/search?' + params, function (data) {
        render_template(data);
    });
}

function render_template(data) {
    console.log(data);
    var template = $('#template').html();
    var rendered = Mustache.render(template, data);
    $('#results').html(rendered);
    $('html,body').animate({ scrollTop: 0 }, 300);
}

$(document).ready(function () {
    $('#search-page-form').submit(function(event) {
        event.preventDefault();
        get_search_response();
    });
});

$(document).on('change', '.xapian-filter', function(event) {
    get_search_response();
});
