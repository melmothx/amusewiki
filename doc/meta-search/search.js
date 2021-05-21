function get_search_response() {
    var params = $('#search-page-form').serialize();
    $.get('/search/ajax?' + params, function (data) {
        var url = window.location.pathname + '?' + params;
        console.log("Rendering " + url);
        window.history.pushState('Search', 'Search', url);
        render_template(data);
    });
}

function render_template(data) {
    console.log(data);
    var template = $('#template').html();
    var rendered = Mustache.render(template, data);
    $('#query').val(data.params.query);
    $('#results').html(rendered);
    $('html,body').animate({ scrollTop: 0 }, 300);
}

function set_page(page) {
    $('input#request-page').val(page);
}

$('#search-page-form').submit(function(event) {
    event.preventDefault();
    set_page(1);
    get_search_response();
});

$(document).on('change', '.xapian-filter', function(event) {
    set_page(1);
    get_search_response();
});

$(document).on('click', '.search-page', function(event) {
    event.preventDefault();
    var page = $(this).data('page');
    if (page) {
        set_page(page);
        get_search_response();
    }
});

$(document).on('click', '#reset-filters', function(event) {
    $('.xapian-filter-checkbox').prop('checked', false);
    set_page(1);
    get_search_response();
});

$(document).ready(function() {
    var query = window.location.search;
    if (query) {
        $.get('/search/ajax' + query, function (data) {
            render_template(data);
        });
    }
});
