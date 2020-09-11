/**
 * Marker Handler management
 *
 * @author Furqan Wasi<furqan@weareavp.com>
 *
 */
function MarkersHanlderDescription(identifier, keyword) {
    var selfMH = this;

    this.identifier = identifier;
    this.tab_type = 'description';
    this.last_button_action = 'next';
    this.collection_resource = {};
    this.search_keyword = keyword;
    this.$input = $("#search_text");
    // clear button
    this.$clearBtn = $(".cancel_button_description.description." + selfMH.identifier);
    // prev button
    this.$prevBtn = $(".back_button_description.description." + selfMH.identifier),
        // next button
        this.$nextBtn = $(".next_button_description.description." + selfMH.identifier),
        // the context where to search
        this.contentDescription = ".single_value_non_tombstone",
        // jQuery object to save <mark> elements
        this.$results = [],
        // the class that will be appended to the current
        // focused element
        this.currentClass = "current",
        // top offset for the jump (the search bar)
        this.offsetTop = 50,
        // the current index of the focused element of current page
        this.currentIndex = 0,

        // the current index of the focused element globally
        this.globalCurrentIndex = 0,
        this.markers_common = {};

    this.initialize = function () {
        selfMH.markers_common = new MarkersCommon();
        this.aviary_handler = new App();
        selfMH.initMarker(selfMH.search_keyword, selfMH.identifier);
    };

    this.initMarker = function (search_text, class_name) {
        if (search_text != '' && search_text !== 'undefined') {
            setTimeout(function(){
                $(".single_value_non_tombstone").mark(search_text, {
                    "element": "span",
                    "className": "highlight-marker mark " + class_name,
                    "caseSensitive": false,
                    "separateWordSearch": false
                });
                $($('.single_value_non_tombstone .highlight-marker.mark.' + class_name)[0]).addClass('current')
            }, 1000);

        }

        setTimeout(function () {
            init_marker_buttons();
        }, 100);

        $('.cancel_button').unbind('click');
        selfMH.update_result_current_index();
    };

    this.actionBasedMethodExc = function (response, container, caller, requestData) {
        switch (requestData.action) {
            case 'remove_search_term':
                location.reload();
                break;
        }
    };


    this.handlecallback = function (response, container, requestData) {
        switch (requestData.action) {
            case 'remove_search_term':
                location.reload();
                break;
        }
    };

    this.update_result_current_index = function () {
        let type = window.location.pathname.substr(window.location.pathname.lastIndexOf('/') + 1);
        let types = ["description", "index", "transcript"];
        if (!types.includes(type)) {
            if ($('.info_tabs .nav-link.active.show').length > 0)
                type = $('.info_tabs .nav-link.active.show').data('tab');
            else
                type = 'description'
        }
        selfMH.tab_type = type;
        if (selfMH.tab_type.toLowerCase() == 'description') {
            selfMH.$results[selfMH.tab_type] = $('.single_value_non_tombstone').find(".mark." + selfMH.identifier);
        }
    };

    const init_marker_buttons = function () {

        /**
         * Clears the search
         */
        selfMH.$clearBtn.on("click", function () {
            $(selfMH.contentDescription).unmark();
            selfMH.$input.val("").focus();
        });

        /**
         * Next and previous search jump to
         */
        selfMH.$nextBtn.add(selfMH.$prevBtn).unbind('click');
        selfMH.$nextBtn.add(selfMH.$prevBtn).on("click", function () {
            selfMH.update_result_current_index();
            if (selfMH.tab_type == 'description') {
                if (typeof selfMH.$results[selfMH.tab_type] == 'undefined' || selfMH.$results[selfMH.tab_type].length <= 0) {
                    selfMH.$results[selfMH.tab_type] = $('.single_value_non_tombstone').find(".mark." + selfMH.identifier);
                }

                if (selfMH.$results[selfMH.tab_type].length) {
                    if (selfMH.currentIndex < 0) {
                        selfMH.currentIndex = selfMH.$results[selfMH.tab_type].length - 1;
                    }
                    if (selfMH.currentIndex > selfMH.$results[selfMH.tab_type].length - 1) {
                        selfMH.currentIndex = 0;
                    }
                    $(this).parents('li').find('.current_location').text(selfMH.currentIndex + 1);
                    jumpToDescription();
                    selfMH.currentIndex += $(this).is(selfMH.$prevBtn) ? -1 : 1;
                }
            }
        });

        $('.clear_search_video_cus').on('click', function () {
            $('.highlight-marker').removeClass('current-active-index');
            $('#search_text').val('');
            $('.seach_form_cus').submit();
        });

    };
    const remove_marker_classes = function () {
        $('.highlight-marker').removeClass('current-active-index');
        $(".highlight-marker").removeClass('current');
    }

    const jumpToDescription = function () {
        remove_marker_classes();
        if (selfMH.$results[selfMH.tab_type].length) {
            var position,
                $current = selfMH.$results[selfMH.tab_type].eq(selfMH.currentIndex);
            selfMH.$results[selfMH.tab_type].removeClass(selfMH.currentClass);
            $($current).addClass(selfMH.currentClass);
            try {
                $('.mCustomScrollbar').mCustomScrollbar("scrollTo", '.current', {scrollInertia: 200, timeout: 1});

            } catch (e) {

            }
        }
    }
}
