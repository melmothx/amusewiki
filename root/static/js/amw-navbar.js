/* the navbar is fixed only on scroll up */
$(document).ready(function() {
    var previous = 0;
    var hash = window.location.hash || '';
    $(window).scroll(function() {
        var scroll = $(window).scrollTop();
        var newhash = window.location.hash;
        var hash_changed = hash != newhash ? 1 : 0;
        if (scroll > 0 && scroll < previous && !hash_changed) {
            $('#amw-nav-bar-top').addClass('navbar-fixed-top');
        }
        else {
            $('#amw-nav-bar-top').removeClass('navbar-fixed-top');
        }
        previous = scroll;
        hash = newhash;
    })
});
