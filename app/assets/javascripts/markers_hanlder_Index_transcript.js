/**
 * Marker Handler management
 *
 * @author Furqan Wasi<furqan@weareavp.com>
 *
 */
function MarkerHandlerIndexTranscript(identifier, keyword) {
    var selfMHIT = this;

    this.identifier = identifier;
    this.tab_type = 'transcript';
    this.last_button_action = 'next';
    var lastActiveAnnotation = '';
    this.collection_resource = {};
    this.search_keyword = keyword;
    this.$input = $("#search_text");
    // clear button
    this.$clearBtn = $(".cancel_button_other." + selfMHIT.identifier);
    // prev button
    this.$prevBtn = $(".back_button_other." + selfMHIT.identifier),
        // next button
        this.$nextBtn = $(".next_button_other." + selfMHIT.identifier),
        // the context where to search
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
        this.globalCurrentIndex = 0,
        this.markers_common = {};

    this.initialize = function () {
        selfMHIT.markers_common = new MarkersCommon();
        this.aviary_handler = new App();
        $(selfMHIT.contentTranscript).unmark();
        $(selfMHIT.contentIndex).unmark();
    };

    this.initMarkerIndexTranscript = function (type) {
        if (selfMHIT.search_keyword != '' && selfMHIT.search_keyword !== 'undefined') {
            $('.file_' + type + '_mark_custom .highlight-marker').unbind('click').bind('click', function () {
                $(this).parents('div.content_section').prev('div.timecode_section').children('a').trigger('click');
            });
        }
        setTimeout(function () {
            init_marker_buttons();
        }, 100);
    }


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

    const init_marker_buttons = function () {
        /**
         * Clears the search
         */
        selfMHIT.$clearBtn.on("click", function () {
            $(selfMHIT.contentTranscript).unmark();
            $(selfMHIT.contentIndex).unmark();
            selfMHIT.$input.val("").focus();
        });

        /**
         * Next and previous search jump to
         */
        $(document).off('click', ".next_button_other."+ selfMHIT.identifier + ",.back_button_other."+ selfMHIT.identifier);
        document_level_binding_element(".next_button_other."+ selfMHIT.identifier + ",.back_button_other."+ selfMHIT.identifier, 'click', function () {
            if ($(this).hasClass('index')) {
                selfMHIT.tab_type = 'index';
            } else {
                selfMHIT.tab_type = 'transcript';
            }
            handle_index_transcript(this);
        }, true);

        $('.clear_search_video_cus').on('click', function () {
            $('.highlight-marker').removeClass('current-active-index');
            $('#search_text').val('');
            $('.seach_form_cus').submit();
        });

    };

    const handleActiveChangeAnnotation = function (annotationElement) {
        if (lastActiveAnnotation != annotationElement) {
            lastActiveAnnotation = annotationElement;
            return true;
        }
        lastActiveAnnotation = annotationElement;
        return false;
    };

    const annotationSearchMarker = function (information, element, selfMHIT, movement) {

        if(handleActiveChangeAnnotation(information[0])){
            $('.close.close_annotation').click();
        }
        let identifier = $('.next_button_other:hover, .back_button_other:hover').data('identifire');
        let current = $('.readable-text.annotation-information p').find('.highlight-marker.mark.' + identifier)[parseInt(information[1], 10)];

        if (!$('.annotation_marker.' + information[0]).hasClass('active')) {
            $('#identifier_movement').val(movement.toString());
            $('#clicked_identifier').val(identifier);
            setTimeout(function () {
                $('.annotation_marker.' + information[0]).click();
            }, 200);

            $('.transcript #overlay-counters').removeClass('d-none');
        }
        $('.' + selfMHIT.tab_type.toLowerCase() + '_point_container').mCustomScrollbar("scrollTo", '.annotation_marker.' + information[0], {scrollInertia: 200, timeout: 1});
        return current;
    };

    const handle_index_transcript = function (element) {
        let $current = {};
        let number = $(element).hasClass('back_button_other') ? -1 : 1;
        let is_next_button = $(element).hasClass('next_button');

        let response_hits = selfMHIT.markers_common.transcript_hits_information(selfMHIT.collection_resource);
        let total_page = response_hits.total_page;
        let all_hits = response_hits.all_hits;

        if (selfMHIT.tab_type.toLowerCase() == 'index') {
            try {
                total_page = selfMHIT.collection_resource.indexes.current_selected_total_page(selfMHIT.tab_type.toLowerCase(), selfMHIT.collection_resource.indexes.selected_index, false);
                all_hits = selfMHIT.collection_resource.index_hits_count[selfMHIT.collection_resource.selected_index][$(element).data('identifire')];
            } catch (err) {
                all_hits = [];
                err;
            }
        } else {
            try {
                total_page = selfMHIT.collection_resource.transcripts.current_selected_total_page(selfMHIT.tab_type.toLowerCase(), selfMHIT.collection_resource.transcripts.selected_transcript, false)
                all_hits = selfMHIT.collection_resource.transcript_hits_count[selfMHIT.collection_resource.selected_transcript][$(element).data('identifire')];
            } catch (err) {
                all_hits = [];
                err;
            }
        }

        if (all_hits.length > 0) {
            let limitedIdentifier = $(element).data('identifire');
            selfMHIT.currentIndex = selfMHIT.markers_common.current_index_update(selfMHIT.currentIndex, is_next_button, selfMHIT.last_button_action);
            if (typeof all_hits[(selfMHIT.currentIndex)] != 'undefined') {
                let information = all_hits[(selfMHIT.currentIndex)].split('||');
                if(information[0].includes('annotation_')) {
                    $current = annotationSearchMarker(information, element, selfMHIT, number);
                } else {
                    $('.close.close_annotation').click();
                    $current = $('#' + information[0]).find('.highlight-marker.mark.' + $(element).data('identifire'))[parseInt(information[1], 10)];
                }
                if ($($current).length > 0) {
                    // found and loading
                    jumpTo($current, total_page);
                    selfMHIT.markers_common.set_count_update(selfMHIT.currentIndex + 1, '.current_location', element, 'li');
                    selfMHIT.currentIndex += number;
                }
            } else if (selfMHIT.currentIndex > (all_hits.length - 1)) {

                //not found loading first occurrence
                selfMHIT.currentIndex = 0;
                let information = all_hits[(selfMHIT.currentIndex)].split('||');
                if(information[0].includes('annotation_')) {
                    $current = annotationSearchMarker(information, element, selfMHIT, number);

                } else {
                    $('.close.close_annotation').click();
                    $current = $('#' + information[0]).find('.highlight-marker.mark.' + limitedIdentifier)[parseInt(information[1], 10)];
                }
                if ($($current).length > 0) {
                    jumpTo($current, total_page);
                    selfMHIT.currentIndex += number;
                    selfMHIT.markers_common.set_count_update(selfMHIT.currentIndex, '.current_location', element, 'li');
                }
            } else if (selfMHIT.currentIndex < 0) {
                // not found loading last occurrence
                selfMHIT.currentIndex = all_hits.length - 1;
                let information = all_hits[(selfMHIT.currentIndex)].split('||');
                if(information[0].includes('annotation_')) {
                    $current = annotationSearchMarker(information, element, selfMHIT, number);
                } else {
                    $('.close.close_annotation').click();
                    $current = $('#' + information[0]).find('.highlight-marker.mark.' + $(element).data('identifire'))[parseInt(information[1], 10)];
                }
                if ($($current).length > 0) {
                    jumpTo($current, total_page);
                    selfMHIT.markers_common.set_count_update(selfMHIT.currentIndex + 1, '.current_location', element, 'li');
                    selfMHIT.currentIndex += number;
                }
            }
            selfMHIT.last_button_action = selfMHIT.markers_common.update_last_action(is_next_button)
        }
    }


    const jumpTo = function ($current, total_page) {
        remove_marker_classes();
        if (total_page > 0) {
            $($current).removeClass(selfMHIT.currentClass);
            if ($($current).length) {

                $('.' + selfMHIT.tab_type.toLowerCase() + '_timeline').removeClass('dark-orange');
                $('.point_index_' + $($current).parents('.index_custom_identifire').data('id')).addClass('dark-orange');
                selfMHIT.collection_resource.current_marker_index = $($current).closest('.' + selfMHIT.tab_type.toLowerCase() + '_time').attr('id');
                $($current).addClass(selfMHIT.currentClass);
                try {
                    scrollTo('.' + selfMHIT.tab_type.toLowerCase() + '_point_container', '.current');
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

}
