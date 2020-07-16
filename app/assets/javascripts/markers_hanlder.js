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
    this.last_button_action = 'next';
    this.collection_resource = {};
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
        this.contentTranscript = ".file_transcript_mark_custom",
        this.contentIndex = ".file_index_mark_custom",
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
        this.globalCurrentIndex = 0;

    this.initialize = function () {
        this.aviary_handler = new App();
        selfMH.initMarker(selfMH.search_keyword, selfMH.identifier);
        $(selfMH.contentDescription).unmark();
        $(selfMH.contentTranscript).unmark();
        $(selfMH.contentIndex).unmark();
    };

    this.initMarkerIndexTranscript = function (type) {
        if (selfMH.search_keyword != '' && selfMH.search_keyword !== 'undefined') {
            $(".file_" + type + "_mark_custom").mark(selfMH.search_keyword, {
                "element": "span",
                "className": "highlight-marker mark " + selfMH.identifier,
                "caseSensitive": false,
                "separateWordSearch": false
            });

            $(".single_value_non_tombstone").mark(selfMH.search_keyword, {
                "element": "span",
                "className": "highlight-marker mark " + selfMH.identifier,
                "caseSensitive": false,
                "separateWordSearch": false
            });

            $('.file_' + type + '_mark_custom .highlight-marker').unbind('click').bind('click', function () {
                $(this).parents('div.content_section').prev('div.timecode_section').children('a').trigger('click');
            });
        }
        selfMH.update_result_current_index();
    }

    this.initMarker = function (search_text, class_name) {

        if (search_text != '' && search_text !== 'undefined') {
            $(".single_value_non_tombstone").mark(search_text, {
                "element": "span",
                "className": "highlight-marker mark " + class_name,
                "caseSensitive": false,
                "separateWordSearch": false
            });
        }

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

    const load_occurrence_by_type = function (total_page, type, first_or_last) {
        let indexPageInfo = load_marker(total_page, selfMH.identifier, type, first_or_last);
        if (type == 'index') {
            selfMH.collection_resource.indexes.specific_page_load('marker_button', indexPageInfo['page_number_inner']);
        } else {
            selfMH.collection_resource.transcripts.specific_page_load_transcript('marker_button', indexPageInfo['page_number_inner']);
        }
    };

    const load_last_occurrence = function () {

    };

    const load_marker = function (total_page, identifire, type, last_or_first) {
        let page_number_inner = false;
        let all_hits = selfMH.collection_resource.transcript_hits_count[selfMH.collection_resource.selected_transcript][identifire];
        if (type == 'index') {
            all_hits = selfMH.collection_resource.index_hits_count[selfMH.collection_resource.selected_index][identifire];
        }

        let loop_all_hits = all_hits[0];
        let indexCurrent = 0;
        if (last_or_first == 'last') {
            loop_all_hits = all_hits[all_hits.length - 1];
        }

        let information = loop_all_hits.split('||');
        page_number_inner = parseInt(information[2], 10);

        return {indexCurrent: indexCurrent, page_number_inner: page_number_inner};
    };

    const init_marker_buttons = function () {

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
        selfMH.$nextBtn.add(selfMH.$prevBtn).unbind('click');
        selfMH.$nextBtn.add(selfMH.$prevBtn).on("click", function () {
            selfMH.update_result_current_index();
            if (selfMH.tab_type == 'description') {
                if (typeof selfMH.$results[selfMH.tab_type] == 'undefined' || selfMH.$results[selfMH.tab_type].length <= 0) {
                    selfMH.$results[selfMH.tab_type] = $('.single_value_non_tombstone').find(".mark." + selfMH.identifier);
                }

                if (selfMH.$results[selfMH.tab_type].length) {
                    selfMH.currentIndex += $(this).is(selfMH.$prevBtn) ? -1 : 1;
                    if (selfMH.currentIndex < 0) {
                        selfMH.currentIndex = selfMH.$results[selfMH.tab_type].length - 1;
                    }
                    if (selfMH.currentIndex > selfMH.$results[selfMH.tab_type].length - 1) {
                        selfMH.currentIndex = 0;
                    }
                    $(this).parents('li').find('.current_location').text(selfMH.currentIndex + 1);
                    jumpToDescription();
                }
            } else {
                $('#' + selfMH.tab_type.toLowerCase() + '-auto-scroll').prop("checked", false);
                let $current = {};
                let number = $(this).is(selfMH.$prevBtn) ? -1 : 1;
                let is_next_button = $(this).hasClass('next_button');
                let total_page = selfMH.collection_resource.transcripts.current_selected_total_page(selfMH.tab_type.toLowerCase(), selfMH.collection_resource.transcripts.selected_transcript, false);
                let all_hits = selfMH.collection_resource.transcript_hits_count[selfMH.collection_resource.selected_transcript][$(this).data('identifire')];

                if (selfMH.tab_type.toLowerCase() == 'index') {
                    total_page = selfMH.collection_resource.indexes.current_selected_total_page(selfMH.tab_type.toLowerCase(), selfMH.collection_resource.indexes.selected_index, false)
                    all_hits = selfMH.collection_resource.index_hits_count[selfMH.collection_resource.selected_index][$(this).data('identifire')];
                }
                if (all_hits.length > 0) {
                    if (selfMH.last_button_action == 'next' && !is_next_button) {
                        selfMH.currentIndex += -2
                    } else if (selfMH.last_button_action == 'back' && is_next_button) {
                        selfMH.currentIndex += +2
                    }
                    if (typeof all_hits[(selfMH.currentIndex)] != 'undefined') {
                        let information = all_hits[(selfMH.currentIndex)].split('||');
                        $current = $('#' + information[0]).find('.highlight-marker.mark.' + $(this).data('identifire'))[parseInt(information[1], 10)];
                        if ($($current).length > 0) {
                            // found and loading
                            jumpTo($current, total_page);
                            $(this).parents('li').find('.current_location').text(selfMH.currentIndex + 1);
                            selfMH.currentIndex += number

                        } else {
                            // found but not on current pages;
                            let information = all_hits[selfMH.currentIndex].split('||');
                            let page_number_index = information[2];
                            if (page_number_index <= 0) {
                                page_number_index = 1;
                            }
                            if (page_number_index >= total_page) {
                                page_number_index = total_page - 1;
                            }
                            if (selfMH.tab_type.toLowerCase() == 'index') {
                                // index new page
                                selfMH.collection_resource.indexes.specific_page_load('marker_button', parseInt(page_number_index, 10));
                            } else {
                                // new transcript page
                                selfMH.collection_resource.transcripts.specific_page_load_transcript('marker_button', parseInt(page_number_index, 10));
                            }
                        }
                    } else if (selfMH.currentIndex > (all_hits.length - 1)) {
                        //not found loading first occurrence
                        selfMH.currentIndex = 0;
                        let information = all_hits[(selfMH.currentIndex)].split('||');
                        $current = $('#' + information[0]).find('.highlight-marker.mark.' + $(this).data('identifire'))[parseInt(information[1], 10)];
                        if ($($current).length > 0) {
                            jumpTo($current, total_page);
                            selfMH.currentIndex += number;
                            $(this).parents('li').find('.current_location').text(selfMH.currentIndex);
                        } else {
                            load_occurrence_by_type(total_page, selfMH.tab_type.toLowerCase(), 'first')
                            $(this).parents('li').find('.current_location').text(selfMH.currentIndex);
                        }
                    } else if (selfMH.currentIndex < 0) {
                        // not found loading last occurrence
                        selfMH.currentIndex = all_hits.length - 1;
                        let information = all_hits[(selfMH.currentIndex)].split('||');
                        $current = $('#' + information[0]).find('.highlight-marker.mark.' + $(this).data('identifire'))[parseInt(information[1], 10)];
                        if ($($current).length > 0) {
                            jumpTo($current, total_page);
                            selfMH.currentIndex += number;
                            $(this).parents('li').find('.current_location').text(selfMH.currentIndex);
                        } else {
                            load_occurrence_by_type(total_page, selfMH.tab_type.toLowerCase(), 'last')
                            $(this).parents('li').find('.current_location').text(selfMH.currentIndex + 1);
                        }
                    }
                    if (is_next_button) {
                        selfMH.last_button_action = 'next';
                    } else {
                        selfMH.last_button_action = 'back';
                    }
                }
            }
        });

        $('.clear_search_video_cus').on('click', function () {
            $('.highlight-marker').removeClass('current-active-index');
            $('#search_text').val('');
            $('.seach_form_cus').submit();
        });

    };

    const jumpTo = function ($current, total_page) {
        remove_marker_classes();
        if (total_page > 0) {
            $($current).removeClass(selfMH.currentClass);
            if ($($current).length) {

                $('.' + selfMH.tab_type.toLowerCase() + '_timeline').removeClass('dark-orange');
                $('.point_index_' + $($current).parents('.index_custom_identifire').data('id')).addClass('dark-orange');
                selfMH.collection_resource.current_marker_index = $($current).closest('.' + selfMH.tab_type.toLowerCase() + '_time').attr('id');
                $($current).addClass(selfMH.currentClass);
                try {
                    $('.' + selfMH.tab_type.toLowerCase() + '_point_container').mCustomScrollbar("scrollTo", '.current');
                } catch (e) {
                    e;
                }
            }
        }
    }

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
                $('.mCustomScrollbar').mCustomScrollbar("scrollTo", '.current');

            } catch (e) {

            }
        }
    }
}
