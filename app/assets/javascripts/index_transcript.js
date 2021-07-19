/**
 * IndexTranscript management
 *
 * @author Nouman Tayyab<nouman@weareavp.com>
 *
 */


function IndexTranscript() {
    var last_scroll_top = 0;
    var data;
    this.mcustomscroll_init = false;
    this.mcustomscroll_init_index = false;
    this.embed = false;
    this.call_type = 'un-toggle';
    this.from_playlist = false;
    this.selected_index = 0;
    this.selected_transcript = 0;
    this.index_loading_call = 0;
    this.transcript_loading_call = 0;
    this.index_page_number = 1;
    this.transcript_page_number = 1;
    this.index_visible_pages = [];
    this.index_number_of_ajax_calls = 0;
    this.transcript_number_of_ajax_calls = 0;
    this.annotation_markers = {};
    this.type = '';
    let that = this;
    var apppend_integer = 0;
    this.setup_prerequisites = function (type, selected_val, resource_obj, embed, from_playlist) {
        this.cuePointType = type;
        this.uploadUrl = $('#new_file_' + that.cuePointType).attr('action');
        this.collection_resource = resource_obj;
        this.from_playlist = from_playlist;
        this.app_helper = new App();
        this.index_visible_pages = [0, 1, 2];
        this.type = type;
        this.embed = embed;
        if (this.type == 'index') {
            this.selected_index = selected_val;
        } else {
            this.selected_transcript = selected_val;
        }
        that.annotation_markers = new AnnotationMarkers();
        that.annotation_markers.collection_resource = that.collection_resource;

    };

    this.pages_be_shown = function (current_page, scroll_moving, type, total_pages, called_from, container, scroll_percent) {
        let ajax_length = Object.keys(that.transcript_loading_call).length;
        if (type == 'index') {
            ajax_length = Object.keys(that.index_loading_call).length;
        }
        if ((called_from != 'scroll' || (scroll_percent < 40 && scroll_moving == 'up') || (scroll_percent > 60 && scroll_moving == 'down')) && ajax_length === 0) {
            let flag_page_changed = false;
            if (scroll_moving == 'up' && current_page >= 2) {
                flag_page_changed = true;
            } else if (scroll_moving == 'down' && total_pages > (current_page + 1)) {
                flag_page_changed = true;
            }
            if (flag_page_changed) {
                if (type == 'index') {
                    that.index_visible_pages = [that.index_page_number - 1, that.index_page_number, that.index_page_number + 1];
                } else {
                    that.transcript_visible_pages = [that.transcript_page_number - 1, that.transcript_page_number, that.transcript_page_number + 1];
                }
                return {
                    page_number: current_page,
                    previous_page: current_page - 2,
                    next_page: current_page + 2,
                    scroll_moving: scroll_moving,
                    type: type
                };
            }
        }
        return false;
    };

    this.initialize = function (selected_val) {
        activeFileUploading();
        activateSortable();
        updateOrder();
        activateDeletePopup();
        activateUpdatePopup();
        editTranscript();
        finishTranscriptEdit();

        $('#selected_' + that.cuePointType).val($('#file_' + that.cuePointType + '_select').val());
        var file_select = selectizeInit('#file_' + that.cuePointType + '_select');
        if ($('#file_' + that.cuePointType + '_select').length > 0) {
            var file_selectize = file_select[0].selectize;
            if (selected_val > 0) {
                file_selectize.setValue(selected_val);
                if (that.cuePointType == 'transcript') {
                    that.annotation_markers.initialize(selected_val);
                }
            }
        }

        $('#file_' + that.cuePointType + '_select').next().find('div.selectize-input > input').prop('disabled', 'disabled');
        activatePoints(this.call_type);
        activatePlayTimecode();

    };

    this.handlecallback = function (response, container, requestData) {
        try {
            eval('this.' + requestData.action + '(response,container,requestData)');
        } catch (err) {
            console.log(err);
        }
    };


    this.first_time_index_call = function () {
        this.all_there_pages(2, 1, 0, 'clear', true);
        this.index_page_number = 1;
    };

    this.all_there_pages = function (next_page, current_page, previous_page, slider, first_call, pass_multiple_calls, extra_info) {
        if (typeof pass_multiple_calls == 'undefined')
            pass_multiple_calls = true;

        that.load_resource_index_init(first_call, 'clear', previous_page, 'previous_page', 'no', pass_multiple_calls, true, extra_info);
        that.index_visible_pages = [previous_page, current_page, next_page];
    };

    this.specific_page_load = function (slider, page_number, pass_multiple_calls, extra_info) {
        if (page_number <= 0) {
            page_number = 1;
        }
        if (typeof pass_multiple_calls == 'undefined')
            pass_multiple_calls = true;
        this.all_there_pages(page_number + 1, page_number, page_number - 1, slider, true, pass_multiple_calls, extra_info);
    };


    this.first_time_transcript_call = function () {
        this.all_there_pages_transcript(2, 1, 0, 'no', true);
        this.transcript_page_number = 1;
    };

    this.all_there_pages_transcript = function (next_page, current_page, previous_page, slider, first_call, pass_multiple_calls, extra_info) {
        if (typeof pass_multiple_calls == 'undefined')
            pass_multiple_calls = true;
        that.load_resource_transcript_init(first_call, slider, previous_page, 'previous_page', 'no', pass_multiple_calls, true, extra_info);
        that.transcript_visible_pages = [previous_page, current_page, next_page];
    };

    this.specific_page_load_transcript = function (slider, page_number, pass_multiple_calls, extra_info) {
        if (page_number <= 0) {
            page_number = 1;
        }
        this.all_there_pages_transcript(page_number + 1, page_number, page_number - 1, slider, true, pass_multiple_calls, extra_info);
    };

    this.call_index_pages = function (information) {
        let page_type = '';
        let load_page = 0;
        if (information['scroll_moving'] == 'up') {
            page_type = 'previous_page';
            load_page = information['previous_page'];
        } else if (information['scroll_moving'] == 'down') {
            page_type = 'next_page';
            load_page = information['next_page'];
        }

        if (information['type'] == 'index') {
            that.load_resource_index_init(false, 'no', load_page, page_type, information['scroll_moving']);
        } else {
            that.load_resource_transcript_init(false, 'no', load_page, page_type, information['scroll_moving']);
        }
    };

    this.load_resource_index_init = function (first_call, sliding, page_number, page_type, movement, pass_multiple_calls, load_previous_next, extra_info) {
        if (Object.keys(that.index_loading_call).length === 0 || (pass_multiple_calls && that.index_number_of_ajax_calls <= 3)) {
            if (typeof load_previous_next == 'undefined') {
                load_previous_next = false;
            }

            that.index_number_of_ajax_calls++;
            $('.index #overlay-counters').removeClass('d-none');
            $('.tab_loader_index').removeClass('d-none');
            $('.tab_loader_index').addClass('d-inline-block');
            if (typeof first_call == 'undefined')
                first_call = false;

            if (typeof sliding == 'undefined')
                sliding = 'no';

            let data = {
                action: 'load_resource_index',
                tabs_size: $('.info_tabs').data('tabs-size'),
                search_size: $('.info_tabs').data('search-size'),
                embed: that.embed,
                selected_index: that.selected_index,
                page_number: page_number,
                first_call: first_call,
                sliding: sliding,
                page_type: page_type,
                keywords: that.collection_resource.search_text_val,
                movement: movement,
                load_previous_next: load_previous_next,
                pass_multiple_calls: pass_multiple_calls,
                from_playlist: that.collection_resource.from_playlist,
                extra_info: extra_info
            };
            that.index_loading_call = that.app_helper.classAction($('.index-tab').data('template-url'), data, 'html', 'GET', '.index_point_inner_container', that, false);
        }
    };

    const lazy_append_content = function (max, listing_transcripts, element) {
        setTimeout(function () {
            apppend_integer++;
            if ((apppend_integer - 1) < max) {
                let object = listing_transcripts[apppend_integer - 1];
                $('.transcript_html_information').append(object);
                lazy_append_content(max, listing_transcripts, element);
            }
        }, 150)

    }

    const response_handler = function (request, type, container, response, listing_transcripts) {
        if (request['movement'] == 'up' && request['page_type'] == 'previous_page') {
            $('.' + type + '_point_container .next_page_type').remove();
            $('.' + type + '_point_container .current_page_type').addClass('next_page_type').removeClass('current_page_type');
            $('.' + type + '_point_container .previous_page_type').addClass('current_page_type').removeClass('previous_page_type');
        } else if (request['movement'] == 'down' && request['page_type'] == 'next_page') {
            $('.' + type + '_point_container .previous_page_type').remove();
            $('.' + type + '_point_container .current_page_type').addClass('previous_page_type').removeClass('current_page_type');
            $('.' + type + '_point_container .next_page_type').addClass('current_page_type').removeClass('next_page_type');
        }
        if (request['sliding'] == 'timeline' || request['sliding'] == 'marker_button' || request['sliding'] == 'clear' || request['sliding'] == 'marker_button_annotation' || request['sliding'] == 'auto_scroll') {
            $(container).html('');
        }
        if (request['page_type'] == 'previous_page') {


            if ($('.' + type + '_point_inner_container').html().trim() == '')
                $(container).append(response);
            else
                $(container).prepend(response);
            apppend_integer = 0;
            if (type == 'transcript') {
                lazy_append_content(Object.keys(listing_transcripts).length, listing_transcripts, '.transcript_html_information');
            }

            if (request['load_previous_next'] == true && !response.includes('no-access')) {
                if (type == 'index' && (response.match(/index_time /g) || []).length >= 3999) {
                    that.load_resource_index_init(request['first_call'], 'no', parseInt(request['page_number'], 10) + 1, 'current_page', 'no', true, true, request['extra_info']);
                } else if ((response.match(/transcript_time  /g) || []).length >= 3999) {
                    that.load_resource_transcript_init(request['first_call'], 'no', parseInt(request['page_number'], 10) + 1, 'current_page', 'no', true, true,);
                }
            }
        } else if (request['page_type'] == 'current_page') {
            $(container).append(response);
            if (request['load_previous_next'] == true && !response.includes('no-access')) {
                if (type == 'index' && (response.match(/index_time /g) || []).length >= 3999) {
                    that.load_resource_index_init(request['first_call'], 'no', parseInt(request['page_number'], 10) + 1, 'next_page', 'no', true, true, request['extra_info']);
                } else if ((response.match(/transcript_time /g) || []).length >= 3999) {
                    that.load_resource_transcript_init(request['first_call'], 'no', parseInt(request['page_number'], 10) + 1, 'next_page', 'no', true, true);
                }
            }
        } else if (request['page_type'] == 'next_page') {
            that.collection_resource.auto_loading_inprogress = false;
            $(container).append(response);
        }
        let sectionHeight = $('.two_col_custom').height();
        if(sectionHeight > 650)
            sectionHeight = 650;
        if (that.from_playlist) {
            $('.' + type + '_point_container').attr('style', 'height:' + (sectionHeight - 50) + 'px!important;max-height:650px !important;');
        } else {
            $('.' + type + '_point_container').attr('style', 'height:' + (sectionHeight) + 'px!important;max-height:650px !important;');
        }
        if (request['first_call'] == true)
            that.call_type = 'toggle';
        else
            that.call_type = 'un-toggle';
        if (typeof request['extra_info'] != 'undefined' && type == 'index' && request['extra_info'].includes('timecode')) {
            setTimeout(function () {
                try {
                    that.scroll_to_point(type, request['extra_info'])
                } catch (e) {
                    e;
                }
            }, 2000);
        }

        if (request['movement'] == 'down') {
            if (type == 'index') {
                that.index_page_number++;
            } else {
                that.transcript_page_number++;
            }
        } else if (request['movement'] == 'up') {
            if (type == 'index') {
                that.index_page_number--;
            } else {
                that.transcript_page_number--;
            }
        } else if (request['page_type'] == 'current_page') {
            if (type == 'index') {
                that.index_page_number = parseInt(request['page_number'], 10);
            } else {
                that.transcript_page_number = parseInt(request['page_number'], 10);
            }
        }
        that.initialize();
        let scroll_flag = that.mcustomscroll_init;
        if (type == 'index') {
            scroll_flag = that.mcustomscroll_init_index;
        }
        if (type == 'transcript') {
            activate_export($('#file_' + that.cuePointType + '_select').val());
        }
        if (!scroll_flag) {
            $("." + type + "_point_container").mCustomScrollbar('destroy');
            $("." + type + "_point_container").mCustomScrollbar({
                    mouseWheel: {
                        scrollAmount: 250,
                        normalizeDelta: false
                    },
                    updateOnContentResize: true,
                    callbacks: {
                        whileScrolling: function () {
                            if ($("." + type + "_point_container").is(':hover')) {
                                let selected_it = that.selected_transcript;
                                if (type == 'index') {
                                    selected_it = that.selected_index
                                }
                                that.scroll_manager(type, selected_it, this.mcs.draggerTop, this.mcs.topPct);
                            }
                            that.collection_resource.auto_loading_inprogress = false;
                        },
                        onTotalScroll: function () {
                            $("." + type + "_point_container").mCustomScrollbar("scrollTo", this.mcs.top);
                        },
                        onTotalScrollBack: function () {
                            $("." + type + "_point_container").mCustomScrollbar("scrollTo", 0);
                        }
                    }
                }
            );
        } else {
            $("." + type + "_point_container").mCustomScrollbar('update');
        }
        if (type == 'index') {
            that.mcustomscroll_init_index = true;
        } else {
            that.mcustomscroll_init = true;
        }

        if (request['sliding'] == 'marker_button_annotation') {
            setTimeout(function () {
                let all_hits = that.collection_resource.annotation_hits_count[that.collection_resource.selected_transcript];
                let information = all_hits[(that.annotation_markers.currentIndexAnnotation)].split('||');
                let $current = $('#' + information[0]).find('.annotation_marker')[parseInt(information[1], 10)];
                if ($($current).length > 0) {
                    let total_page = that.annotation_markers.collection_resource.transcripts.current_selected_total_page('transcript', that.collection_resource.transcripts.selected_transcript, false);
                    that.annotation_markers.jumpTo($current, total_page);
                }
            }, 1000);

        }
        $('.edit_by_information').addClass('d-none');
        $('.previous_page_type .edit_by_information').removeClass('d-none');
        let marker_load_time = 2000;
        if (type == 'transcript') {
            marker_load_time = (Object.keys(listing_transcripts).length * 200) + 2500;
        }
        if (that.collection_resource.search_text_val != '' && that.collection_resource.search_text_val != 0) {
            setTimeout(function () {
                $.each(that.collection_resource.markerHandlerIT, function (index, object) {
                    object.initMarkerIndexTranscript(type);
                });
            }, marker_load_time);
        }
        $('.loader.loader_custom_' + type).remove();
    };

    this.load_resource_index = function (response, container, request) {
        if (response && (response.includes('index_time') || response.includes('file_index'))) {
            response_handler(request, 'index', container, response);
        }
        if (that.index_number_of_ajax_calls <= 0) {
            $('.index #overlay-counters').addClass('d-none');
        }
        $('.tab_loader_index').addClass('d-none');
        $('.tab_loader_index').removeClass('d-inline-block');

        if (that.collection_resource.search_text_val != '' && that.collection_resource.search_text_val != 0) {
            try {
                let response = searchRelatedObjects('index')
                that.collection_resource.index_infor = response.infor;
                that.collection_resource.index_hits_count = response.hits_count;
                that.collection_resource.index_page_wise_count = response.page_wise_count;
                that.collection_resource.index_time_wise_page = response.time_wise_page;
                that.collection_resource.total_index_wise = response.total_type_wise;
            } catch (err) {

            }

            try {
                if (that.collection_resource.index_infor[that.collection_resource.resource_file_id]['total-index']) {
                    $('.index_count_tab').text(that.collection_resource.index_infor[that.collection_resource.resource_file_id]['total-index']);
                    $('.index_count_tab').removeClass('d-none');
                }
                $.each(that.collection_resource.total_index_wise[that.collection_resource.selected_index], function (index, value) {
                    $('.index.total_count.' + index).text(value);
                });
            } catch (err) {

            }

            let cuePointTypeCurrent = 'index';
            var file_select = selectizeInit('#file_index_select');
            if ($('#file_' + cuePointTypeCurrent + '_select').length > 0 && that.collection_resource.index_infor.single_index_count) {
                addCountsToDropDown(file_select, that.collection_resource.index_infor.single_index_count);
            }
        }

        if (request['sliding'] == 'timeline') {
            that.to_index_transcript_point($('.index_timeline.dark-orange').data());
        }
        setTimeout(function () {
            that.index_loading_call = {};
            that.index_number_of_ajax_calls--;
            if (that.index_number_of_ajax_calls < 0) {
                that.index_number_of_ajax_calls = 0;
            }
            if (that.index_number_of_ajax_calls <= 0) {
                $('.index #overlay-counters').addClass('d-none');
            }
            $('.tab_loader_index').addClass('d-none');
            $('.tab_loader_index').removeClass('d-inline-block');
        }, 1300);

    };

    const searchRelatedObjects = function (type) {
        try {
            let infor = JSON.parse($('.' + type + '_count').val());
            let hits_count = JSON.parse($('.' + type + '_count').val()).hits;
            let page_wise_count = JSON.parse($('.' + type + '_count').val()).page_wise;
            let time_wise_page = JSON.parse($('.' + type + '_time_wise').val());
            let total_type_wise = {}
            if (type == 'index') {
                total_type_wise = that.collection_resource.total_type_wise = JSON.parse($('.' + type + '_count').val()).total_index_wise;
            } else {
                total_type_wise = that.collection_resource.total_type_wise = JSON.parse($('.' + type + '_count').val()).total_transcript_wise;
            }
            return {
                total_type_wise: total_type_wise,
                time_wise_page: time_wise_page,
                page_wise_count: page_wise_count,
                hits_count: hits_count,
                infor: infor
            }
        } catch (e) {

        }
        return {total_type_wise: {}, time_wise_page: {}, page_wise_count: {}, hits_count: {}, infor: {}}
    }

    const addCountsToDropDown = function (file_select, count_total) {
        var file_selectize = file_select[0].selectize;
        for (cnt in file_selectize.options) {
            let data = file_selectize.options[cnt];
            let value = data['value'];
            if (count_total[value] > 0) {
                let count = count_total[value];
                let text = data['text'];
                if (count > 0 && !text.includes('badge-danger')) {
                    file_selectize.updateOption(value, {
                        text: '<span class="badge badge-pill badge-danger">' + count + '</span> ' + text,
                        value: value
                    });
                }
            }
        }
    }
    const hashToArray = function (hash) {
        var search_term = new Array();
        for (var key in hash) {
            search_term.push(hash[key]);
        }
        return search_term
    }

    this.load_resource_transcript_init = function (first_call, sliding, page_number, page_type, movement, pass_multiple_calls, load_previous_next, extra_info) {

        if (Object.keys(that.transcript_loading_call).length === 0 || (pass_multiple_calls && that.transcript_number_of_ajax_calls <= 3)) {
            that.transcript_number_of_ajax_calls++;
            $('.transcript #overlay-counters').removeClass('d-none');
            $('.tab_loader_transcript').removeClass('d-none');
            $('.tab_loader_transcript').addClass('d-inline-block');
            if (typeof first_call == 'undefined')
                first_call = false;

            if (typeof sliding == 'undefined')
                sliding = 'no';


            let data = {
                action: 'load_resource_transcript',
                tabs_size: $('.info_tabs').data('tabs-size'),
                search_size: $('.info_tabs').data('search-size'),
                embed: that.embed,
                selected_transcript: that.selected_transcript,
                page_number: page_number,
                first_call: first_call,
                sliding: sliding,
                page_type: page_type,
                movement: movement,
                keywords: that.collection_resource.search_text_val,
                load_previous_next: load_previous_next,
                pass_multiple_calls: pass_multiple_calls,
                from_playlist: that.collection_resource.from_playlist,
                extra_info: extra_info
            };
            this.transcript_loading_call = that.app_helper.classAction($('.transcript-tab').data('template-url'), data, 'JSON', 'GET', '.transcript_point_inner_container', that, false);
        }
    };

    this.load_resource_transcript = function (response_raw, container, request) {
        let response = response_raw.body_response;
        let listing_transcripts = response_raw.listing_transcripts;

        if (response && (response.includes('index_html_information') || response.includes('file_transcript'))) {
            response_handler(request, 'transcript', container, response, listing_transcripts);
        }
        if (that.transcript_number_of_ajax_calls <= 0) {
            $('.transcript #overlay-counters').addClass('d-none');
        }
        $('.tab_loader_transcript').addClass('d-none');
        $('.tab_loader_transcript').removeClass('d-inline-block');
        if (that.collection_resource.search_text_val != '' && that.collection_resource.search_text_val != 0) {
            try {
                let response = searchRelatedObjects('transcript');
                that.collection_resource.transcript_infor = response.infor;
                that.collection_resource.transcript_hits_count = response.hits_count;
                that.collection_resource.transcript_page_wise_count = response.page_wise_count;
                that.collection_resource.transcript_time_wise_page = response.time_wise_page;
                that.collection_resource.total_transcript_wise = response.total_type_wise;

            } catch (e) {

            }

            try {
                that.collection_resource.annotation_hits_count = JSON.parse($('.annotation_count').val()).hits;
                that.collection_resource.annotation_hits_ids = JSON.parse($('.annotation_count').val()).annotation_ids;
            } catch (e) {

            }

            try {
                that.collection_resource.annotationSearchCount = JSON.parse($('.annotation_search_count').val());
            } catch (e) {

            }
            try {
                if (that.collection_resource.annotation_hits_count['total'][that.collection_resource.selected_transcript]) {
                    $('.annotation_current_total').text(that.collection_resource.annotation_hits_count['total'][that.collection_resource.selected_transcript]);
                }
            } catch (err) {

            }
            try {
                if (that.collection_resource.transcript_infor[that.collection_resource.resource_file_id]['total-transcript'] || that.collection_resource.annotationSearchCount[that.collection_resource.resource_file_id].total) {

                    let fileTranscriptCount = 0;
                    let annotationCount = 0;
                    if (parseInt(that.collection_resource.transcript_infor[that.collection_resource.resource_file_id]['total-transcript'], 10)) {
                        fileTranscriptCount = that.collection_resource.transcript_infor[that.collection_resource.resource_file_id]['total-transcript'];
                    }

                    if (parseInt(that.collection_resource.annotationSearchCount[that.collection_resource.resource_file_id].total, 10)) {
                        annotationCount = that.collection_resource.annotationSearchCount[that.collection_resource.resource_file_id].total;
                    }

                    $('.transcript_count_tab').text(fileTranscriptCount + annotationCount);
                    $('.transcript_count_tab').removeClass('d-none');
                }
                $.each(that.collection_resource.total_transcript_wise[that.collection_resource.selected_transcript], function (index, value) {
                    let total = 0;
                    try {
                        total = parseInt(value, 10) + that.collection_resource.annotationSearchCount[that.collection_resource.resource_file_id].total_transcript_wise[that.collection_resource.selected_transcript][index].total;
                    } catch (e) {
                        total = value;
                    }

                    $('.transcript.total_count.' + index).text(total);
                });

            } catch (err) {

            }


            try {
                let fileSelectAnnotation = $('#annotation_set_select').selectize();
                let fileSelectizeAnnotation = fileSelectAnnotation[0].selectize;
                for (cnt in fileSelectizeAnnotation.options) {
                    let data = fileSelectizeAnnotation.options[cnt];
                    let value = data['value'];
                    let countAnnotations = that.collection_resource.annotationSearchCount[that.collection_resource.resource_file_id].total_set_wise.total;
                    let text = data['text'];
                    if (countAnnotations > 0 && !text.includes('badge-danger')) {
                        fileSelectizeAnnotation.updateOption(value, {
                            text: '<span class="badge badge-pill badge-danger">' + countAnnotations + '</span> ' + text,
                            value: value
                        });
                    }
                }
            } catch (err) {
            }

            let cuePointTypeCurrent = 'transcript';
            var file_select = selectizeInit('#file_transcript_select');
            if ($('#file_' + cuePointTypeCurrent + '_select').length > 0 && that.collection_resource.transcript_infor.single_transcript_count) {
                addCountsToDropDown(file_select, that.collection_resource.transcript_infor.single_transcript_count);
            }
        }

        setTimeout(function () {
            if (lastAnnotationId > 0) {
                firstTimeAnnotation = 1;
                $('.annotation_' + lastAnnotationId).trigger('click');
                lastAnnotationId = 0;
                $('.transcript_point_container').mCustomScrollbar("scrollTo", $('.annotation_marker.active'), {
                    scrollInertia: 10,
                    timeout: 1
                });
            } else if ($('#transcript-tab').hasClass('active') && $('.transcript_point_container').hasClass('enable_annotation') && $('.annotation_flag').length > 0) {
                firstTimeAnnotation = 1;
                $($('.annotation_flag')[0]).trigger('click');
            }
            that.transcript_loading_call = {};
            that.transcript_number_of_ajax_calls--;
            if (that.transcript_number_of_ajax_calls < 0) {
                that.transcript_number_of_ajax_calls = 0;
            }
            if (that.transcript_number_of_ajax_calls <= 0) {
                $('.transcript #overlay-counters').addClass('d-none');
            }
        }, 1000);
    };

    this.to_index_transcript_point = function (data) {
        $('#' + data.type + '-tab').click();
        $('.highlight-marker').removeClass('current-active-index');
        $(".highlight-marker").removeClass('current');

        if (typeof $('#' + data.type + '_timecode_' + data.point) != 'undefined') {
            that.scroll_to_point(data.type, '#' + data.type + '_timecode_' + data.point)
        }
    };

    this.scroll_to_point = function (type, element) {
        let element_update = '.file_' + type + '_';
        if (type == 'index') {
            element_update += this.selected_index;

        } else {
            element_update += this.selected_transcript;
        }
        element = element_update + ' ' + element;

        if ($(element).length > 0 && element != that.last_point_visited) {
            type = type.toLowerCase();
            that.last_point_visited = element;
            if (type == 'transcript') {
                $('.transcript_time').removeClass('active');
                $(element).addClass('active');
            }
            scrollTo('.' + type + '_point_container', element);
        }
    };

    this.current_selected_total_page = function (type, selected, floor_flag) {
        if (typeof floor_flag == 'undefined') {
            floor_flag = true;
        }
        if (floor_flag === false) {
            return parseFloat($('#total_' + type + '_points_' + selected).val());
        } else {
            return Math.floor(parseFloat($('#total_' + type + '_points_' + selected).val()));
        }
    };

    this.scroll_manager = function (type, selected, current_position, current_percentage) {
        let total_pages = that.current_selected_total_page(type, selected);
        if (total_pages > 2) {
            let st = current_position;
            let movement = '';
            that.recent_scroll_top = false;
            that.recent_scroll_bottom = false;

            if (st != last_scroll_top) {
                if (st >= last_scroll_top) {
                    movement = 'down';
                } else {
                    movement = 'up';
                }
            }
            last_scroll_top = st;

            if (movement != '') {
                let information = that.pages_be_shown(that.transcript_page_number, movement, type, total_pages, 'scroll', '.' + type + '_point_container', current_percentage);
                if (type == 'index') {
                    information = that.pages_be_shown(that.index_page_number, movement, type, total_pages, 'scroll', '.' + type + '_point_container', current_percentage);
                }
                if (information) {
                    that.call_index_pages(information);
                }
            }
        }
    };

    this.index_scroll = function (type, selected) {
        var lastScrollTop = 0;
        var recentScrollTop = false;
        var recentScrollBottom = false;
        bindingElement('.' + type + '_point_container', 'scroll', function () {
            let total_pages = that.current_selected_total_page(type, selected);
            if (total_pages > 2) {
                let st = $(this).scrollTop();
                let movement = '';
                let outter_this = this;

                clearTimeout($.data(this, "scrollIsTop"));
                clearTimeout($.data(this, "scrollIsBottom"));

                $.data(this, "scrollIsTop", setTimeout(function () {
                    if (st == 0 && !recentScrollTop) {
                        recentScrollTop = true;
                        window.setTimeout(() => {
                            recentScrollTop = false;
                            $(outter_this).scrollTop(30);
                        }, 500)
                    }
                }, 250));
                $.data(this, "scrollIsBottom", setTimeout(function () {
                    if ($(outter_this).scrollTop() + $(outter_this).innerHeight() >= $(outter_this)[0].scrollHeight) {
                        recentScrollBottom = true;
                        window.setTimeout(() => {
                            recentScrollBottom = false;
                            $(outter_this).scrollTop($(outter_this)[0].scrollHeight - 30);
                        }, 500)
                    }
                }, 250));

                if (st > lastScrollTop) {
                    movement = 'down';
                } else {
                    movement = 'up';
                }
                lastScrollTop = st;

                if (type == 'index') {
                    let information = that.pages_be_shown(that.index_page_number, movement, type, total_pages, 'scroll', '.' + type + '_point_container');
                    if (information) {
                        that.call_index_pages(information);
                    }
                } else {
                    let information = that.pages_be_shown(that.transcript_page_number, movement, type, total_pages, 'scroll', '.' + type + '_point_container');
                    if (information) {
                        that.call_index_pages(information);
                    }
                }
            }
        });

    };

    const capitalize = function (s) {
        if (typeof s !== 'string') return '';
        return s.charAt(0).toUpperCase() + s.slice(1);
    };

    let activateUpdatePopup = function () {
        $(".text-danger").html("");
        $('#' + that.cuePointType + '_update_btn').unbind('click').click(function () {
            current = $('#file_' + that.cuePointType + '_select');
            $('#new_file_' + that.cuePointType).attr('action', that.uploadUrl + '/' + current.val());
            $('#' + that.cuePointType + '_upload_title').html('Update "' + current.text() + '" ' + capitalize(that.cuePointType));
            $('#file_' + that.cuePointType + '_title').val(current.text());
            $('#file_' + that.cuePointType + '_language')[0].selectize.setValue($('.file_' + that.cuePointType + '_' + current.val()).data().language);
            $('#file_' + that.cuePointType + '_is_public')[0].selectize.setValue($('.file_' + that.cuePointType + '_' + current.val()).data().public.toString());
            $('#file_' + that.cuePointType + '_description').val($('.file_' + that.cuePointType + '_' + current.val()).data().description.toString());
            if (that.cuePointType == 'transcript') {
                let current_transcript = $('.file_' + that.cuePointType + '_' + current.val());
                if (current_transcript.data('webvtt')) {
                    $('.is_caption_section').removeClass('d-none');
                    $('#file_transcript_is_caption').prop('checked', current_transcript.data('cc'));
                } else {
                    $('#file_transcript_is_caption').prop('checked', false);
                    $('.is_caption_section').addClass('d-none');
                }
            }

            $('.upload_' + that.cuePointType + '_btn').html('Update ' + capitalize(that.cuePointType));
            $('.upload_' + that.cuePointType + '_btn').unbind("click").bind("click", function () {

                $(this).prop("disabled", true);
                $.ajax({
                    url: $('#new_file_' + that.cuePointType).attr('action'),
                    data: $('#new_file_' + that.cuePointType).serialize(),
                    type: 'POST',
                    dataType: 'json',
                    success: function (response) {
                        checkErrors(response[0]);
                    },
                });
                $(this).html("Processing... ");
            });
        });

        $('#' + that.cuePointType + '_upload').on('hidden.bs.modal', function () {
            $('#new_file_' + that.cuePointType).attr('action', that.uploadUrl);
            $('#' + that.cuePointType + '_upload_title').html(capitalize(that.cuePointType) + ' Upload');
            $('#file_' + that.cuePointType + '_title').val('');
            $('#file_' + that.cuePointType + '_language')[0].selectize.setValue('en');
            $('#file_' + that.cuePointType + '_is_public')[0].selectize.setValue('false');
            $('.upload_' + that.cuePointType + '_btn').html('Upload ' + capitalize(that.cuePointType));
            if (that.cuePointType == 'transcript') {
                $('.is_caption_section').addClass('d-none');
                $('#file_transcript_is_caption').prop('checked', false);
            }

            $('.upload_' + that.cuePointType + '_btn').unbind("click");
        });
    };

    let activateDeletePopup = function () {
        $('#delete_' + that.cuePointType).click(function () {
            $('#modalPopupTitle').html('Delete ' + capitalize(that.cuePointType));
            currentInfo = $('#file_' + that.cuePointType + '_select');
            message = 'Are you sure you want to delete this ' + that.cuePointType + ' ("' + currentInfo.text() + '") from Aviary?';
            if (that.cuePointType == 'transcript') {
                currentTranscript = $('.file_transcript_' + currentInfo.val()).data();
                if (currentTranscript.annotation != '') {
                    message += ' If you do, you will lose the annotations that you have created for this transcript. To export the annotations, select the option to "Export to Text with Annotations" before continuing with the delete process.';
                }
            }
            $('#modalPopupBody').html(message);
            $('#modalPopupFooterYes').attr('href', $(this).data().url + currentInfo.val());
            $('#modalPopup').modal('show');
        });
    };

    let activatePlayTimecode = function () {
        document_level_binding_element('.play-timecode', 'click', function () {
            let currentTime = $(this).data().timecode;
            if ($('#avalon_widget').length > 0) {
                player_widget('set_offset', {'offset': currentTime});
                player_widget('play');
            } else {
                playerSpecificTimePlay = currentTime;
                player_widget.currentTime(currentTime);
                player_widget.play();
            }
            if ($(this).parent().hasClass('annotation_text')) {
                $('.transcript_point_container').mCustomScrollbar("scrollTo", $('.annotation_marker.active'), {
                    scrollInertia: 10,
                    timeout: 1
                });
            }
        }, true)
    };

    let activatePoints = function (call_type) {
        let selected_element = '.file_' + that.cuePointType + '_' + $('#file_' + that.cuePointType + '_select').val();
        showAnnotationSet(selected_element);
        $(selected_element).removeClass('d-none');
        $('.' + that.cuePointType + '_' + $('#file_' + that.cuePointType + '_select').val()).removeClass('d-none');
        $('.file_' + that.cuePointType + '_' + $('#file_' + that.cuePointType + '_select').val()).toggleClass('selected_' + that.cuePointType + 'file');
        $('#file_' + that.cuePointType + '_select').unbind('change');
        $('#file_' + that.cuePointType + '_select').change(function () {
            if (that.cuePointType == 'transcript')
                apppend_integer = 0;
            $('.' + that.cuePointType + '_point_inner_container').html('');
            if (that.cuePointType == 'index') {
                that.index_page_number = 1;
                that.collection_resource.selected_index = that.selected_index = $(this).val();
                that.first_time_index_call();
            } else {
                that.index_page_number = 1;
                that.collection_resource.selected_transcript = that.selected_transcript = $(this).val();
                that.first_time_transcript_call();
            }

            $('.file_' + that.cuePointType).addClass('d-none');
            $('.' + that.cuePointType + '_timeline').addClass('d-none');
            $('.file_' + that.cuePointType + '_' + $(this).val()).toggleClass('d-none');
            $('.' + that.cuePointType + '_' + $(this).val()).toggleClass('d-none');
            $('.file_' + that.cuePointType).removeClass('selected_' + that.cuePointType + 'file');
            $('.file_' + that.cuePointType + '_' + $('#file_' + that.cuePointType + '_select').val()).addClass('selected_' + that.cuePointType + 'file');
            $('#selected_' + that.cuePointType).val($('#file_' + that.cuePointType + '_select').val());
            showAnnotationSet('.file_' + that.cuePointType + '_' + $('#file_' + that.cuePointType + '_select').val());
            that.collection_resource.init_scoll(that.cuePointType, that.collection_resource.currentTime, true);
            try {
                if (typeof that.collection_resource.events_tracker != 'undefined')
                    that.collection_resource.events_tracker.track_tab_hits(that.cuePointType, true);
            } catch (e) {
                e;
            }
            activate_export($('#file_' + that.cuePointType + '_select').val());
            if (that.collection_resource.search_text_val != '' && that.collection_resource.search_text_val != 0) {
                $.each(that.collection_resource.markerHandlerIT, function (_index, object) {
                    object.currentIndex = 0;
                    $('.current_location').text(object.currentIndex);
                });
            }
            if (that.cuePointType == 'transcript') {
                that.annotation_markers.switch_marker_arrows(that.collection_resource.selected_transcript);
            }

        });

        $('[data-toggle="tooltip"]').tooltip();
    };

    let activate_export = function (currentId) {
        if (that.cuePointType == 'transcript') {
            try {
                let selected_element = '.file_' + that.cuePointType + '_' + currentId;
                let dataInfo = $(selected_element).data();

                if (dataInfo.access) {
                    $('.export_transcript').removeClass('d-none');
                    $('.text_export').attr('href', $('.text_export').data('url') + '/' + currentId);
                } else {
                    $('.export_transcript').addClass('d-none');
                }
                if (dataInfo.annotation_access && dataInfo.annotation != '') {
                    $('.textanno_export').removeClass('d-none');
                    $('.textanno_export').attr('href', $('.textanno_export').data('url') + '/' + currentId);
                } else {
                    $('.textanno_export').addClass('d-none');
                    $('.textanno_export').attr('href', 'javascript://;');
                }
                if (dataInfo.json) {
                    $('.json_export').removeClass('d-none');
                    $('.json_export').attr('href', $('.json_export').data('url') + '/' + currentId);
                } else {
                    $('.json_export').addClass('d-none');
                    $('.json_export').attr('href', 'javascript://;');
                }
                if (dataInfo.webvtt) {
                    $('.webvtt_export').removeClass('d-none');
                    $('.webvtt_export').attr('href', $('.webvtt_export').data('url') + '/' + currentId);
                } else {
                    $('.webvtt_export').addClass('d-none');
                    $('.webvtt_export').attr('href', 'javascript://;');
                }
                if (dataInfo.edit) {
                    $('#delete_transcript').hide();
                    $('#transcript_update_btn').hide();
                } else {
                    $('#delete_transcript').show();
                    $('#transcript_update_btn').show();
                }
            } catch (e) {
                e;
            }
        }
    };

    let activateSortable = function () {
        $('#sortable_' + that.cuePointType).sortable({
            handle: '.handle',
            activate: function (event, ui) {
                data = $(this).sortable('toArray');
            },
            update: function (event, ui) {
                data = $(this).sortable('toArray');
            }
        }).disableSelection();
        data = $('#sortable_' + that.cuePointType).sortable('toArray');
    };

    let updateOrder = function () {
        $('.sort_' + that.cuePointType + '_btn').unbind('click').bind('click', function () {
            let cc = [];
            if (that.cuePointType == 'transcript') {
                $('.cc_checkbox').each(function () {
                    if ($(this).is(":checked")) {
                        cc.push($(this).val());
                    }
                });
            }
            $.ajax({
                url: $(this).data("url"),
                type: "PATCH",
                data: {sort_list: data, cc: cc},
                success: function () {
                    window.location.reload();
                }
            });
        });
    };

    let activeFileUploading = function () {
        $('#file_' + that.cuePointType + '_associated_file').fileupload({
            formData: $("#new_file_" + that.cuePointType).serializeArray(),
            autoUpload: false,
            submit: function (e, data) {
                data.formData = $("#new_file_" + that.cuePointType).serializeArray();
                return true;
            },
            add: function (e, data) {
                $.each(data.files, function (index, file) {
                    $("#file_name_" + that.cuePointType).html(file.name + "<br/>");
                });
                var fileExtension = ['text/vtt', 'text/webvtt', 'vtt', 'webvtt'];
                if (that.cuePointType == 'transcript') {
                    if ($.inArray($('#file_name_transcript').text().split('.').pop().toLowerCase(), fileExtension) == -1) {
                        $('.is_caption_section').addClass('d-none');
                        $('.remove_title_section').addClass('d-none');
                    } else {
                        $('.is_caption_section').removeClass('d-none');
                        $('.remove_title_section').removeClass('d-none');
                    }
                }
                $('.upload_' + that.cuePointType + '_btn').unbind("click").bind("click", function () {
                    $(this).prop("disabled", true);
                    data.submit();
                    $(this).html("Processing...");
                });
            },
            progressall: function (e, data) {
                var progress = parseInt(data.loaded / data.total * 100, 10);
                $('#progress' + that.cuePointType + ' .progress-bar').css(
                    "width",
                    progress + "%"
                );
            },
            done: function (e, data) {
                result = data.result[0];
                checkErrors(result);
            }
        });
    };

    const checkErrors = function (result) {
        $(".modal-body .organization-section .text-danger").html("");
        if (Object.size(result.errors) > 0) {
            $('#progress .progress-bar').css("width", "0%");
            $('.upload_' + that.cuePointType + '_btn').html("Upload " + capitalize(that.cuePointType)).prop("disabled", false);
            for (cnt in result.errors) {
                $('.modal-body .organization-section .' + cnt).html(result.errors[cnt]);
            }
        } else {
            $('.upload_' + that.cuePointType + '_btn').hide();
            $('#' + that.cuePointType + '_upload_success').html(capitalize(that.cuePointType) + " file uploaded successfully.");
            setTimeout("location.reload();", 2000);
        }
    };

    const editTranscript = function () {
        if ($('.edit_transcript').length > 0) {
            $('.edit_transcript').unbind('click').bind('click', function () {
                let url = btoa($(this).data().url);
                let width = $(window).width() - 150;
                let height = $(window).height();
                window.open('/transcript-editor/index.html?transcript=' + url, 'winname', 'directories=0,titlebar=0,toolbar=0,location=0,status=0,menubar=0,scrollbars=no,resizable=no,width=' + width + ',height=' + height);
                setTimeout('window.location.reload();', 2000);
            });
        }

    };

    const finishTranscriptEdit = function () {
        if ($('.finish_editing').length > 0) {
            var interval = setInterval(function () {
                localKey = localStorage.getItem('transcript_finish');
                if (localKey == 'true') {
                    localStorage.setItem('transcript_finish', false);
                    clearInterval(interval);
                    $('.finish_editing').trigger('click');
                }
            }, 5000);

            $('.finish_editing').unbind('click').bind('click', function () {
                file_transcript = {
                    'file_transcript': {
                        'is_edit': false,
                    }
                };
                $.ajax({
                    url: $('.finish_editing').data('url'),
                    data: file_transcript,
                    type: 'POST',
                    dataType: 'json',
                    success: function (response) {
                        window.location.reload();
                    },

                });
            });
        }
    };

    const showAnnotationSet = function (selected_element) {
        if (that.cuePointType == 'transcript') {
            if ($(selected_element).data('annotation_access')) {
                if ($(selected_element).data('annotation') != '') {
                    let file_selectize = $('#annotation_set_select')[0].selectize;
                    file_selectize.setValue($(selected_element).data('annotation'));
                    $('.show-annotation-box').removeClass('d-none');
                    $('.annotation-option').removeClass('d-none');
                    $('.add-annotation-box').addClass('d-none');
                    $('.transcript_enable_annotation_section').removeClass('d-none');
                } else {
                    $('.show-annotation-box').addClass('d-none');
                    $('.annotation-option').addClass('d-none');
                    $('.add-annotation-box').removeClass('d-none');
                    $('.transcript_enable_annotation_section').addClass('d-none');
                }
                $('.annotation-box-holder').addClass('d-none');
                $('.annotation-box').addClass('d-none');
                $('.annotation_flag, .annotation_marker').removeClass('active');
                $('.annotation_delete_section').addClass('d-none');
                $('.annotation-box .text-box').removeClass('delete');
            } else {
                $('.annotation-box-holder').addClass('d-none');
                $('.show-annotation-box').addClass('d-none');
                $('.annotation-option').addClass('d-none');
                $('.add-annotation-box').addClass('d-none');
                $('.transcript_enable_annotation_section').addClass('d-none');
            }

        }
    };

}
