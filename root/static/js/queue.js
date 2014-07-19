$(document).ready(function() {
    $('.nojs').hide();
});

function update_status(url, reloaded) {
    $.getJSON(url, function(data) {
        console.log(data.status);
        if (!reloaded) {
            $('#waiting').show();
        }
        $('pre#job-logs').text(data.logs);
        $('.bbstatusstring').text(data.status_loc);
        if (data.errors) {
            $('#job-errors').show().text(data.errors);
        }
        else {
            $('#job-errors').hide();
        }
        // recurse if pending or taken
        if ((data.status == 'pending') ||
            (data.status == 'taken')) {
            var funct = 'update_status("' + url + '", 1)';
            setTimeout(funct, 1000);
        }
        else {
            $('#waiting').hide();
        }
        if (data.status == 'completed') {
            $('a.completed').text(data.message);
            $('a.completed').attr('href', data.produced_uri);
            $('.completed').show();
            if (data.sources ) {
                $('a.sources').attr('href', data.sources);
                $('a.sources').show();
            }
        }
    });
};


