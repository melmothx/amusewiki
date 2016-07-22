// Reference: http://ignorethecode.net/blog/2010/04/20/footnotes/
$(document).ready(function() {
    Footnotes.setup();
});

var Footnotes = {
    footnotetimeout: false,
    setup: function() {
        var footnotelinks = $("a.footnote");
        
        footnotelinks.unbind('mouseover', Footnotes.footnoteover);
        footnotelinks.unbind('mouseout',  Footnotes.footnoteoout);
        
        footnotelinks.bind('mouseover', Footnotes.footnoteover);
        footnotelinks.bind('mouseout',  Footnotes.footnoteoout);
    },
    footnoteover: function() {
        clearTimeout(Footnotes.footnotetimeout);
        $('#footnotediv').stop();
        $('#footnotediv').remove();
        
        var id = $(this).attr('href');
        var position = $(this).offset();
    
        var div = $(document.createElement('div'));
        div.attr('id','footnotediv');
        div.bind('mouseover', Footnotes.divover);
        div.bind('mouseout',  Footnotes.footnoteoout);

        var el = $(id).parent();
        div.html($(el).html());
        // remove the marker
        div.find("a.footnotebody").remove();
        var window_width = $(window).width();
        var footnote_width = 400;
        if (window_width < footnote_width) {
            footnote_width = window_width - 20;
        }
        div.css({
            position:'absolute',
            width: footnote_width,
            opacity:0.9
        });
        div.addClass('panel panel-default panel-body');
        $(document.body).append(div);
        var footnote_offset = footnote_width + 20;
        var left = position.left;
        if(left + footnote_offset  > $(window).width() + $(window).scrollLeft())
            left = $(window).width() - footnote_offset + $(window).scrollLeft();
        var top = position.top+20;
        if(top + div.height() > $(window).height() + $(window).scrollTop())
            top = position.top - div.height() - 15;
        div.css({
            left:left,
            top:top
        });
    },
    footnoteoout: function() {
        Footnotes.footnotetimeout = setTimeout(function() {
            $('#footnotediv').animate({
                opacity: 0
            }, 600, function() {
                $('#footnotediv').remove();
            });
        },100);
    },
    divover: function() {
        clearTimeout(Footnotes.footnotetimeout);
        $('#footnotediv').stop();
        $('#footnotediv').css({
                opacity: 0.9
        });
    }
}
