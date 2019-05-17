function add_flag_to_internal_anchors() {
    $('.amusewiki-internal-anchor-box').remove();
    $('.text-amuse-internal-anchor').each(function(i) {
        var scream = window.location.href.match(/\/action\/.*\/edit/) ? 1 : 0;
        var link = $(this).attr('id');
        var flag = $('<span>');
        var parent_position = $(this).closest('div#thework').offset();
        var position = $(this).offset();
        var anchor = $('<a>');
        var div = $('<div>');

        flag.attr('class', 'fa fa-flag amusewiki-internal-anchor-box');
        flag.css({ padding: '2px',
                   color: scream ? '#860000' : 'black',
                   opacity: scream ? 1 : 0.25,
                 });
        anchor.attr('href', '#' + link);
        // console.log(link);
        anchor.append(flag);
        if (scream) {
            $(this).append(anchor);
            return;
        }
        else if (parent_position) {
            div.attr('id', 'amusewiki-internal-anchor-box-' + i);
            div.attr('class', 'amusewiki-internal-anchor-box');
            div.append(anchor);
            $(document.body).append(div);
            div.css({
                position: 'absolute',
                top: position.top,
                left: parent_position.left - anchor.width(),
                opacity: 0.7
            });
        }
    });

}

$(document).ready(function() {
    add_flag_to_internal_anchors();
    $('#widepage').imagesLoaded()
        .always(function() {
            add_flag_to_internal_anchors();
        });
    $(window).resize(function() {
        add_flag_to_internal_anchors();
    });
});
