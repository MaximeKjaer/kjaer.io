jQuery(document).ready(function($){
    	var secondaryNav = $('.cd-secondary-nav'),
		secondaryNavTopPosition = secondaryNav.offset().top,
		taglineOffesetTop = $('#cd-intro-tagline').offset().top + $('#cd-intro-tagline').height() + parseInt($('#cd-intro-tagline').css('paddingTop').replace('px', '')),
		contentSections = $('.cd-section');
    
//smooth scrolling when clicking on the secondary navigation items
	secondaryNav.find('ul a').on('click', function(event){
        if (!window.location.origin)
            window.location.origin = window.location.protocol+"//"+window.location.host;
        if (window.location.origin + '/' != this.href) {
            event.preventDefault();
            var target= $(this.hash);
            var hash = this.hash;
            $('body,html').animate({
                'scrollTop': target.offset().top - secondaryNav.height() + 1
                }, 400, function () {
                    location.hash = hash;
                }
            );
            //on mobile - close secondary navigation
            $('.cd-secondary-nav-trigger').removeClass('menu-is-open');
            secondaryNav.find('ul').removeClass('is-visible');
        }
    });
    
    if (location.hash != "") {
        target = $(location.hash);
        $('body,html').animate({
        	'scrollTop': target.offset().top - secondaryNav.height() + 1
        	}, 400
        ); 
    }
});