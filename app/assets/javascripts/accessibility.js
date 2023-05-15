/**
 * Accessibility
 *
 * @author Nouman Tayyab<nouman@weareavp.com>
 *
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 */
function Accessibility() {
    this.initialize = function () {
        let button = $('#accessibility_button');
        var buttonHeight = button.outerHeight();
        var buttonOffset = $(window).height() - button[0].getBoundingClientRect().bottom;

        var adjustLocation = function () {
            let footer = $('.footer_section');
            if (footer.length > 0) {
                let footerOffset = $(window).height() - footer[0].getBoundingClientRect().top;
                if (footerOffset >= buttonOffset + buttonHeight / 2) {
                    button.css({bottom: +footerOffset - buttonHeight / 2 + 'px'})
                } else {
                    button.css({bottom: buttonOffset + 'px'})
                }
            }
        };

        button.keydown(function (e) {
            if (e.keyCode == 32) {
                e.target.click();
            }
        });

        $(window).on('scroll resize load', adjustLocation);

        $(window).on('show.bs.collapse hide.bs.collapse', function() {
            var timerId = setInterval(adjustLocation, 10);
            setTimeout(function() {clearInterval(timerId)}, 500);
        });
        tabChanges();
    }
    const tabChanges = () => {
        document_level_binding_element('.vjs-big-play-button', 'focus', function () {
            $(".shareHolder").css({"visibility": "visible", "opacity": 1});
        });

        $(window).on('load', function () {
            $("#player_section iframe").attr("tabindex", -1)
        });
    }
}