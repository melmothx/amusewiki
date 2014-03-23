$(document).ready(function() {
    $('.nojs').hide();
});

function update_status(url) {
    $.getJSON(url, function(data) {
        console.log(data.status);
        if ((data.status == 'pending') ||
            (data.status == 'taken')) {
            var funct = 'update_status("' + url + '")';
            setTimeout(funct, 1000);
        }
    });
};


