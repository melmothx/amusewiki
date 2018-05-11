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

$('#search-page-form').submit(function(event) {
    event.preventDefault();
    get_search_response();
});

$(document).on('change', '.xapian-filter', function(event) {
    get_search_response();
});

$(document).on('click', '.search-page', function(event) {
    event.preventDefault();
    var page = $(this).data('page');
    if (page) {
        $('input#request-page').val(page);
        get_search_response();
    }
});
