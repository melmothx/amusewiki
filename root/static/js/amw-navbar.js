/* the navbar is fixed only on scroll up */
$(document).ready(function() {
    var previous = 0;
    var hash = window.location.hash || '';
    $(window).scroll(function() {
        var scroll = $(window).scrollTop();
        var newhash = window.location.hash || '';
        if (hash === newhash && scroll > 0 && scroll < previous) {
            if ((previous - scroll) > 120) {
                $('#amw-nav-bar-top').addClass('navbar-fixed-top');
                previous = scroll;
            }
            /*
            else {
               console.log("Not registering skip " + previous + ' ' + scroll);
            }
            */
        }
        else {
            $('#amw-nav-bar-top').removeClass('navbar-fixed-top');
            previous = scroll;
        }
        hash = newhash;
    })
});
