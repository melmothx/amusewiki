/*
The navbar is fixed on scroll up.
Static until JS loads. Otherwise absolute.
But avoid changing between fixed and absolute when a menu is open.
Related CSS: `body[style*="padding-top"] .navbar:not(.navbar-fixed-top)`.
*/
$(document).ready(function() {
    var previous = 0;
    var hash = window.location.hash || '';
    var $window = $(window);
    var $body = $(document.body);
    var $navbar = $('#amw-nav-bar-top');
    function updateNavbar() {
        var scroll = $window.scrollTop();
        var newhash = window.location.hash || '';
        var topMenuOpen = $navbar.find('.collapse.in');
        var menuOpen =
            topMenuOpen.length || $navbar.find('.dropdown.open').length;
        var navbarHeightPlusMargin =
            $navbar.outerHeight(true) - (topMenuOpen.height() || 0);
        $body.css('padding-top', navbarHeightPlusMargin);
        if (hash === newhash && scroll > 0 && scroll < previous && !menuOpen) {
            if ((previous - scroll) > 120) {
                $navbar.addClass('navbar-fixed-top');
                previous = scroll;
            }
            /*
            else {
               console.log("Not registering skip " + previous + ' ' + scroll);
            }
            */
        }
        else if (!menuOpen) {
            $navbar.removeClass('navbar-fixed-top');
            previous = scroll;
        }
        hash = newhash;
    }
    $window.scroll(updateNavbar);
    updateNavbar();
});
