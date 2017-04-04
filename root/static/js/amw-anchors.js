function add_flag_to_internal_anchors() {
    $('.amusewiki-internal-anchor-box').remove();
    $('.text-amuse-internal-anchor').each(function(i) {
        // console.log(i);
        var link = $(this).attr('id');
        var position = $(this).offset();
        var div = $(document.createElement('div'));
        div.attr('id', 'amusewiki-internal-anchor-box-' + i);
        div.attr('class', 'amusewiki-internal-anchor-box');
        var parent_position = $(this).parent().offset();
        var flag = $('<span>');
        flag.attr('class', 'fa fa-flag');
        flag.css({ padding: '2px',
                   color: 'black',
                   opacity: 0.25,
                 });
        var anchor = $('<a>');
        anchor.attr('href', '#' + link);
        // console.log(link);
        anchor.append(flag);
        div.append(anchor);
        $(document.body).append(div);
        div.css({
            position: 'absolute',
            top: position.top,
            left: parent_position.left - anchor.width(),
            opacity: 0.7
        });
        // console.log(div.width());

    });

}

$(document).ready(function() {
    add_flag_to_internal_anchors();
    $(window).resize(function() {
        add_flag_to_internal_anchors();
    });
});
