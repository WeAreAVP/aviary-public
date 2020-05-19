/**
 * Marker Handler management
 *
 * @author Furqan Wasi<furqan@weareavp.com>
 *
 */
function MarkerHandler(identifier, keyword) {
    var selfMH = this;

    this.identifier = identifier;
    this.tab_type = 'description';
    this.search_keyword = keyword;
    this.$input = $("#search_text");
    // clear button
    this.$clearBtn = $(".cancel_button." + selfMH.identifier);
    // prev button
    this.$prevBtn = $(".back_button." + selfMH.identifier),
        // next button
        this.$nextBtn = $(".next_button." + selfMH.identifier),
        // the context where to search
        this.contentDescription = ".single_value_non_tombstone",
        this.contentTranscript = ".selected_transcriptfile .file_transcript_mark_custom",
        this.contentIndex = ".selected_indexfile .file_index_mark_custom",
        // jQuery object to save <mark> elements
        this.$results = [],
        // the class that will be appended to the current
        // focused element
        this.currentClass = "current",
        // top offset for the jump (the search bar)
        this.offsetTop = 50,
        // the current index of the focused element
        this.currentIndex = 0;

    this.initialize = function () {
        this.aviary_handler = new App();
        selfMH.initMarker(selfMH.search_keyword, selfMH.identifier);

    };

    this.initMarker = function (search_text, class_name) {

        if (search_text != '' && search_text !== 'undefined') {
            $(".file_index_mark_custom, .file_transcript_mark_custom, .single_value_non_tombstone").mark(search_text, {
                "element": "span",
                "className": "highlight-marker mark " + class_name,
                "caseSensitive": false,
                "separateWordSearch": false
            });

        }
        $('.file_index_mark_custom .highlight-marker, .file_transcript_mark_custom .highlight-marker').unbind('click').bind('click', function () {
            $(this).parents('div.content_section').prev('div.timecode_section').children('a').trigger('click');
        });
        setTimeout(function () {
            init_marker_buttons()
        }, 100);
        $('.cancel_button').unbind('click');

        $('.cancel_button, .clear_search_video_cus_all').on('click', function () {
            $('.loadingCus').show();
            let data = {
                action: 'remove_search_term',
                identifier: $(this).data('identifire'),
                remove_search_text: true,
            };
            selfMH.aviary_handler.classAction($(this).data('url'), data, 'json', 'POST', '', selfMH, false);
        });
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

    this.update_result_current_index = function (currentTab) {
        selfMH.tab_type = currentTab.charAt(0).toUpperCase() + currentTab.slice(1);
        selfMH.$results[selfMH.tab_type] = eval("$(selfMH.content" + selfMH.tab_type + ')').find(".mark." + selfMH.identifier);
        selfMH.currentIndex = 0;
        if (selfMH.$results[[selfMH.tab_type]].length > 0) {
            $(selfMH.$results[selfMH.tab_type][0]).addClass(selfMH.currentClass);
        }
    };

    const init_marker_buttons = function () {

        /**
         * Jumps to the element matching the currentIndex
         */


        /**
         * Clears the search
         */
        selfMH.$clearBtn.on("click", function () {
            $(selfMH.contentDescription).unmark();
            $(selfMH.contentTranscript).unmark();
            $(selfMH.contentIndex).unmark();
            selfMH.$input.val("").focus();
        });

        /**
         * Next and previous search jump to
         */
        selfMH.$nextBtn.add(selfMH.$prevBtn).on("click", function () {
            if (selfMH.$results[selfMH.tab_type].length) {
                selfMH.currentIndex += $(this).is(selfMH.$prevBtn) ? -1 : 1;
                if (selfMH.currentIndex < 0) {
                    selfMH.currentIndex = selfMH.$results[selfMH.tab_type].length - 1;
                }
                if (selfMH.currentIndex > selfMH.$results[selfMH.tab_type].length - 1) {
                    selfMH.currentIndex = 0;
                }
                $(this).parents('li').find('.current_location').text(selfMH.currentIndex + 1);
                jumpTo();
            }
        });
        $('.clear_search_video_cus').on('click', function () {
            $('.highlight-marker').removeClass('current-active-index');
            $('#search_text').val('');
            $('.seach_form_cus').submit();
        });

    };

    const jumpTo = function () {
        $('.highlight-marker').removeClass('current-active-index');
        $(".highlight-marker").removeClass('current');
        if (selfMH.$results[selfMH.tab_type].length) {
            var position,
                $current = selfMH.$results[selfMH.tab_type].eq(selfMH.currentIndex);
            selfMH.$results[selfMH.tab_type].removeClass(selfMH.currentClass);
            if ($current.length) {
                $('.index_timeline').removeClass('dark-orange');
                $('.point_index_' + $($current).parents('.index_custom_identifire').data('id')).addClass('dark-orange');
                $current.addClass(selfMH.currentClass);
            }

            try {
                $('.mCustomScrollbar').mCustomScrollbar("scrollTo", '.current');

            } catch (e) {

            }
        }
    }

}
