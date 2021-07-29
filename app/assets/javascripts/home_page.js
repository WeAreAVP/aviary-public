/**
 * Home Management
 *
 * @author Nouman Tayyab <nouman@weareavp.com>
 *
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 *
 */

function HomePage() {
    var self = this,
        container, running = false,
        currentY = 0,
        targetY = 0,
        oldY = 0,
        maxScrollTop = 0,
        minScrollTop, direction, onRenderCallback = null,
        fricton = 0.9,
        vy = 0,
        stepAmt = 1,
        minMovement = 0.1,
        ts = 0.1;

    this.orgInitialize = function () {
        var url = document.location.toString();
        if (url.match('#')) {
            $('.nav-tabs a[href="#' + url.split('#')[1] + '"]').tab('show');
        }
        $('.nav-tabs a').on('shown.bs.tab', function (e) {
            window.location.hash = e.target.hash;
        });
    };

    this.initialize = function () {
        bannerSlider();
        $('.mouse').click(function () {
            $([document.documentElement, document.body]).animate({
                scrollTop: $(".mouse").offset().top - 20
            }, 1000);

        });
        $('.move-to-how').click(function () {
            $([document.documentElement, document.body]).animate({
                scrollTop: $(".about-landing").offset().top - 70
            }, 1000);

        });
        $(window).smoothWheel();
    };
    var bannerSlider = function () {
        var flipContainer = $('.flipster'),
            flipItemContainer = flipContainer.find('.flip-items'),
            flipItem = flipContainer.find('li');
        if (flipItem.length > 0) {
            flipContainer.flipster({
                itemContainer: flipItemContainer,
                itemSelector: flipItem,
                loop: true,
                style: 'flat',
                spacing: -1.9,
                scrollwheel: false,
                buttons: true
            });
        }
    };
    var updateScrollTarget = function (amt) {
        targetY += amt;
        vy += (targetY - oldY) * stepAmt;

        oldY = targetY;
    };
    var render = function () {
        if (vy < -(minMovement) || vy > minMovement) {

            currentY = (currentY + vy);
            if (currentY > maxScrollTop) {
                currentY = vy = 0;
            } else if (currentY < minScrollTop) {
                vy = 0;
                currentY = minScrollTop;
            }

            container.scrollTop(-currentY);

            vy *= fricton;

            if (onRenderCallback) {
                onRenderCallback();
            }
        }
    };
    var animateLoop = function () {
        if (!running) return;
        requestAnimFrame(animateLoop);
        render();
    };
    var onWheel = function (e) {
        var evt = e.originalEvent;

        var delta = evt.detail ? evt.detail * -1 : evt.wheelDelta / 40;
        var dir = delta < 0 ? -1 : 1;
        if (dir != direction) {
            vy = 0;
            direction = dir;
        }

        //reset currentY in case non-wheel scroll has occurred (scrollbar drag, etc.)
        currentY = -container.scrollTop();
        updateScrollTarget(delta);
    };
    /*
         * http://jsbin.com/iqafek/2/edit
         */
    var normalizeWheelDelta = function () {
        // Keep a distribution of observed values, and scale by the
        // 33rd percentile.
        var distribution = [],
            done = null,
            scale = 30;
        return function (n) {
            // Zeroes don't count.
            if (n == 0) return n;
            // After 500 samples, we stop sampling and keep current factor.
            if (done != null) return n * done;
            var abs = Math.abs(n);
            // Insert value (sorted in ascending order).
            outer: do { // Just used for break goto
                for (var i = 0; i < distribution.length; ++i) {
                    if (abs <= distribution[i]) {
                        distribution.splice(i, 0, abs);
                        break outer;
                    }
                }
                distribution.push(abs);
            } while (false);
            // Factor is scale divided by 33rd percentile.
            var factor = scale / distribution[Math.floor(distribution.length / 3)];
            if (distribution.length == 500) done = factor;
            return n * factor;
        };
    }();
    /*
        * http://paulirish.com/2011/requestanimationframe-for-smart-animating/
        */
    window.requestAnimFrame = (function () {
        return window.requestAnimationFrame ||
            window.webkitRequestAnimationFrame ||
            window.mozRequestAnimationFrame ||
            window.oRequestAnimationFrame ||
            window.msRequestAnimationFrame ||
            function (callback) {
                window.setTimeout(callback, 1000 / 60);
            };
    })();

    $.fn.smoothWheel = function () {
        var options = jQuery.extend({}, arguments[0]);
        return this.each(function (index, elm) {

            if (!('ontouchstart' in window)) {
                container = $(this);
                container.bind("mousewheel", onWheel);
                container.bind("DOMMouseScroll", onWheel);

                //set target/old/current Y to match current scroll position to prevent jump to top of container
                targetY = oldY = container.scrollTop();
                currentY = -targetY;

                minScrollTop = container.get(0).clientHeight - container.get(0).scrollHeight;
                if (options.onRender) {
                    onRenderCallback = options.onRender;
                }
                if (options.remove) {
                    log("122", "smoothWheel", "remove", "");
                    running = false;
                    container.unbind("mousewheel", onWheel);
                    container.unbind("DOMMouseScroll", onWheel);
                } else if (!running) {
                    running = true;
                    animateLoop();
                }

            }
        });
    };
    if ($(window).width() >= 960) {


        var controller;

        $(function () {
            controller = new ScrollMagic.Controller();

            var tween1 = TweenMax.to('#tween', 0.5, {
                backgroundColor: 'red',
                color: 'white'
            });

            var scene1 = new ScrollMagic.Scene({
                triggerElement: '#scene1',
                duration: 3830,
                triggerHook: (0.3),
            }).setPin('#pin', {
                pushFollowers: false
            })
                .setTween(tween1)
                .addTo(controller);

        });

        var controller2;

        $(function () {
            controller2 = new ScrollMagic.Controller();

            var tween2 = TweenMax.to('#tween', 0.5, {
                backgroundColor: 'red',
                color: 'white'
            })

            var scene2 = new ScrollMagic.Scene({
                triggerElement: '#scene2',
                duration: 3830,
                triggerHook: (0.16),
            }).setPin('#pin2', {
                pushFollowers: false
            })
                .setTween(tween2)
                .addTo(controller2);

        });
    }


    if ($(window).width() > 1400) {

        scene1 = new ScrollMagic.Scene({triggerElement: "#trigger"});

        // change the position of the trigger
        $("#pin").css("top", 30);
        scene1.duration(4150);
        // immediately let the scene know of this change
        scene1.refresh();
    }

    if ($(window).width() > 1600) {

        scene1 = new ScrollMagic.Scene({triggerElement: "#trigger"});

        // change the position of the trigger
        $("#pin").css("top", 40);
        scene1.duration(4150);
        // immediately let the scene know of this change
        scene1.refresh();
    }
}
