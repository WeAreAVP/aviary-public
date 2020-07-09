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
        selfMH.tab_type = window.location.pathname.substr(window.location.pathname.lastIndexOf('/') + 1);
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


                let $current = {};
                let number = $(this).is(selfMH.$prevBtn) ? -1 : 1;
                let flag_change_page = false;
                let total_page = selfMH.collection_resource.indexes.current_selected_total_page(selfMH.tab_type.toLowerCase(), selfMH.collection_resource.indexes.selected_index, false)
                if (selfMH.tab_type.toLowerCase() == 'index') {
                    if (selfMH.collection_resource.total_index_wise[selfMH.collection_resource.selected_index][$(this).data('identifire')] > 0) {
                        let all_hits = selfMH.collection_resource.index_hits_count[selfMH.collection_resource.selected_index][$(this).data('identifire')];
                        if (typeof all_hits[selfMH.currentIndex] != 'undefined') {
                            let information = all_hits[selfMH.currentIndex].split('||');
                            $current = $('#' + information[0]).find('.highlight-marker.mark.' + $(this).data('identifire'))[parseInt(information[1], 10)];
                            let page_number_index = information[2];
                            if ($($current).length <= 0 && page_number_index != selfMH.collection_resource.indexes.index_page_number) {
                                flag_change_page = true;
                                if (page_number_index <= 0) {
                                    page_number_index = 1;
                                }
                                selfMH.collection_resource.indexes.index_page_number = page_number_index;
                            }
                        }
                    } else {
                        return false;
                    }
                } else {
                    total_page = selfMH.collection_resource.transcripts.current_selected_total_page(selfMH.tab_type.toLowerCase(), selfMH.collection_resource.transcripts.selected_transcript, false)
                    if (selfMH.collection_resource.total_transcript_wise[selfMH.collection_resource.selected_transcript][$(this).data('identifire')] > 0) {
                        let all_hits = selfMH.collection_resource.transcript_hits_count[selfMH.collection_resource.selected_transcript][$(this).data('identifire')];
                        if (typeof all_hits[selfMH.currentIndex] != 'undefined') {
                            let information = all_hits[selfMH.currentIndex].split('||');
                            $current = $('#' + information[0]).find('.highlight-marker.mark.' + $(this).data('identifire'))[parseInt(information[1], 10)];
                            let page_number_transcript = information[2];
                            if (page_number_transcript != selfMH.collection_resource.transcripts.transcript_page_number && $($current).length <= 0) {
                                flag_change_page = true;
                                if (page_number_transcript <= 0) {
                                    page_number_transcript = 1;
                                }
                                selfMH.collection_resource.transcripts.transcript_page_number = page_number_transcript;
                            }
                        }
                    } else {
                        return false;
                    }

                }

                let page_number_index = selfMH.collection_resource.indexes.index_page_number;
                let page_number_transcript = selfMH.collection_resource.transcripts.transcript_page_number;

                if (flag_change_page) {
                    if (selfMH.tab_type.toLowerCase() == 'index') {
                        selfMH.collection_resource.indexes.specific_page_load('marker_button', parseInt(page_number_index, 10) + number);
                    } else {
                        selfMH.collection_resource.transcripts.specific_page_load_transcript('marker_button', parseInt(page_number_transcript, 10) + number);
                    }
                    return;
                }

                if ((selfMH.currentIndex + number) < 0) {
                    if (selfMH.tab_type.toLowerCase() == 'index') {
                        selfMH.collection_resource.indexes.specific_page_load('marker_button', parseInt(total_page, 10) - 1);
                        selfMH.currentIndex = selfMH.collection_resource.index_hits_count[selfMH.collection_resource.selected_index][selfMH.identifier].length - 1;
                    } else {
                        selfMH.collection_resource.transcripts.specific_page_load_transcript('marker_button', parseInt(total_page, 10) - 1);
                        selfMH.currentIndex = selfMH.collection_resource.transcript_hits_count[selfMH.collection_resource.selected_transcript][selfMH.identifier].length - 1;
                    }
                    return;
                } else {
                    if (selfMH.tab_type.toLowerCase() == 'index') {
                        if ((selfMH.currentIndex + number) > selfMH.collection_resource.index_hits_count[selfMH.collection_resource.selected_index][selfMH.identifier].length) {
                            selfMH.currentIndex = 1;
                            selfMH.collection_resource.indexes.first_time_index_call();
                            return;
                        }
                    } else {
                        if ((selfMH.currentIndex + number) > selfMH.collection_resource.transcript_hits_count[selfMH.collection_resource.selected_transcript][selfMH.identifier].length) {
                            selfMH.currentIndex = 1;
                            selfMH.collection_resource.transcripts.first_time_transcript_call();
                            return;
                        }
                    }
                }

                if (!flag_change_page) {
                    $($current).addClass(selfMH.currentClass);
                    jumpTo($current, total_page);
                    selfMH.currentIndex += number
                    $(this).parents('li').find('.current_location').text(selfMH.currentIndex);
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
