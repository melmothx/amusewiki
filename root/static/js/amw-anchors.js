function add_flag_to_internal_anchors() {
    $('.amusewiki-internal-anchor-box').remove();
    $('.text-amuse-internal-anchor').each(function(i) {
        var scream = window.location.href.match(/\/action\/.*\/edit/) ? 1 : 0;
        var link = $(this).attr('id');
        var flag = $('<span>');
        flag.attr('class', 'fa fa-flag');
        flag.css({ padding: '2px',
                   color: scream ? '#860000' : 'black',
                   opacity: scream ? 1 : 0.25,
                 });
        var anchor = $('<a>');
        anchor.attr('href', '#' + link);
        // console.log(link);
        anchor.append(flag);
        $(this).append(anchor);
    });

}

$(document).ready(function() {
    add_flag_to_internal_anchors();
    $(window).resize(function() {
        add_flag_to_internal_anchors();
    });
});
