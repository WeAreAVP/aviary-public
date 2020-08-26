/**
 * Accessibility
 *
 * @author Nouman Tayyab<nouman@weareavp.com>
 *
 */
function Accessibility() {
    this.initialize = function () {
        let button = $('#accessibility_button');
        var buttonHeight = button.outerHeight();
        var buttonOffset = $(window).height() - button[0].getBoundingClientRect().bottom;
        button.keydown(function (e) {
            if (e.keyCode == 32) {
                e.target.click();
            }
        });
        $(window).on('scroll resize load', function () {
            let footer = $(".page-footer");
            let footerOffset = $(window).height() - footer[0].getBoundingClientRect().top;
            if (footerOffset >= buttonOffset + buttonHeight / 2) {
                button.css({bottom: +footerOffset - buttonHeight / 2 + 'px'})
            } else {
                button.css({bottom: buttonOffset + 'px'})
            }
        });
    }
}
