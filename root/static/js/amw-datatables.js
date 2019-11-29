$(document).ready(function() {
    var el = $('.amw-datatable').first();
    var init = {
        "lengthMenu": [
            [10, 25, 50, 100, 200, -1],
            [10, 25, 50, 100, 200, "∞"]
        ],
        "pageLength": 25
    };
    if (el.data('ajax-source')) {
        init.ajax = el.data('ajax-source');
    }
    $('.amw-datatable').DataTable(init);
});
