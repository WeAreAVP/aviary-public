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
    this.recent_scroll_top = false;
    this.recent_scroll_bottom = false;
    this.transcript_visible_pages = [];
    this.type = '';

    let that = this;
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

    };

    this.pages_be_shown = function (current_page, scroll_moving, type, total_pages, called_from, container, scroll_percent) {
        let ajax_length = Object.keys(that.transcript_loading_call).length;
        if (type == 'index') {
            ajax_length = Object.keys(that.index_loading_call).length;
        }
        if ((called_from != 'scroll' || (scroll_percent < 30 && scroll_moving == 'up') || (scroll_percent > 70 && scroll_moving == 'down')) && ajax_length === 0) {
            let flag_page_changed = false;
            if (scroll_moving == 'up' && current_page >= 2) {
                flag_page_changed = true;
                current_page = current_page - 1;
            } else if (scroll_moving == 'down' && total_pages > (current_page + 1)) {
                flag_page_changed = true;
                current_page++;
            }
            if (flag_page_changed) {
                if (type == 'index') {
                    that.index_page_number = current_page;
                    that.index_visible_pages = [that.index_page_number - 1, that.index_page_number, that.index_page_number + 1];
                } else {
                    that.transcript_page_number = current_page;
                    that.transcript_visible_pages = [that.transcript_page_number - 1, that.transcript_page_number, that.transcript_page_number + 1];
                }
                return {
                    page_number: current_page,
                    previous_page: current_page - 1,
                    next_page: current_page + 1,
                    scroll_moving: scroll_moving,
                    type: type
                };
            }
        }
        return false;
    };

    this.initialize = function () {
        activeFileUploading();
        activateSortable();
        updateOrder();
        activatePoints(this.call_type);
        activateDeletePopup();
        activateUpdatePopup();
        editTranscript();
        finishTranscriptEdit();
        $('#selected_' + that.cuePointType).val($('#file_' + that.cuePointType + '_select').val());
        var file_select = $('#file_' + that.cuePointType + '_select').selectize();
        if ($('#file_' + that.cuePointType + '_select').length > 0) {
            var file_selectize = file_select[0].selectize;

            for (cnt in file_selectize.options) {
                let data = file_selectize.options[cnt];
                let value = data['value'];
                if ($('.single_' + that.cuePointType + '_count_' + value).length > 0) {
                    let count = $('.single_' + that.cuePointType + '_count_' + value).data('count');
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
        this.all_there_pages(2, 1, 0, 'no', true);
        this.index_page_number = 1;
    }

    this.all_there_pages = function (next_page, current_page, previous_page, slider, first_call, pass_multiple_calls) {
        if (typeof pass_multiple_calls == 'undefined')
            pass_multiple_calls = true;

        that.load_resource_index_init(first_call, 'clear', current_page, 'current_page', 'no', pass_multiple_calls, true);
        that.index_visible_pages = [previous_page, current_page, next_page];
    }

    this.specific_page_load = function (slider, page_number, pass_multiple_calls) {
        if (page_number <= 0) {
            page_number = 1;
        }
        if (typeof pass_multiple_calls == 'undefined')
            pass_multiple_calls = true;
        this.all_there_pages(page_number + 1, page_number, page_number - 1, slider, true, pass_multiple_calls);
    };

    this.first_time_transcript_call = function () {
        this.specific_page_load_transcript(2, 1, 0, 'no', true);
        this.transcript_page_number = 1;
    }

    this.all_there_pages_transcript = function (next_page, current_page, previous_page, slider, first_call) {
        that.load_resource_transcript_init(first_call, slider, current_page, 'current_page', 'no', true, true);
        that.transcript_visible_pages = [previous_page, current_page, next_page];
    }

    this.specific_page_load_transcript = function (slider, page_number) {
        if (page_number <= 0) {
            page_number = 1;
        }
        this.all_there_pages_transcript(page_number + 1, page_number, page_number - 1, slider, true);
    };

    this.call_index_pages = function (information) {
        let page_type = '';
        let load_page = 0
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

    this.load_resource_index_init = function (first_call, sliding, page_number, page_type, movement, pass_multiple_calls, load_previous_next) {
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
                movement: movement,
                load_previous_next: load_previous_next,
                pass_multiple_calls: pass_multiple_calls
            };
            that.index_loading_call = that.app_helper.classAction($('.index-tab').data('template-url'), data, 'html', 'GET', '.index_point_inner_container', that, false);
        }
    };


    this.load_resource_index = function (response, container, request) {
        if (response && (response.includes('index_time') || response.includes('file_index'))) {

            if (request['movement'] == 'up' && request['page_type'] == 'previous_page') {
                $('.index_point_container .next_page_type').remove();
                $('.index_point_container .current_page_type').addClass('next_page_type').removeClass('current_page_type');
                $('.index_point_container .previous_page_type').addClass('current_page_type').removeClass('previous_page_type');
            } else if (request['movement'] == 'down' && request['page_type'] == 'next_page') {
                $('.index_point_container .previous_page_type').remove();
                $('.index_point_container .current_page_type').addClass('previous_page_type').removeClass('current_page_type');
                $('.index_point_container .next_page_type').addClass('current_page_type').removeClass('next_page_type');
            }
            if (request['sliding'] == 'clear' || request['sliding'] == 'marker_button') {
                $(container).html('');
            }
            if (request['page_type'] == 'current_page') {
                $(container).append(response);
                if (request['load_previous_next'] == true && !response.includes('no-access') && that.current_selected_total_page('index', that.selected_transcript) > 0) {
                    setTimeout(function () {
                        that.load_resource_index_init(request['first_call'], 'no', parseInt(request['page_number'], 10) - 1, 'previous_page', 'no', request['pass_multiple_calls']);
                        that.load_resource_index_init(request['first_call'], 'no', parseInt(request['page_number'], 10) + 1, 'next_page', 'no', request['pass_multiple_calls']);
                    }, 500);
                }
            } else if (request['page_type'] == 'previous_page') {
                $(container).prepend(response);
            } else if (request['page_type'] == 'next_page') {
                $(container).append(response);
            }

            if (that.from_playlist) {
                $('.index_point_container').attr('style', 'height:' + ($('.two_col_custom').height() - 50) + 'px!important;max-height:600px!important;');
            } else {
                $('.index_point_container').attr('style', 'height:' + ($('.two_col_custom').height()) + 'px!important;max-height:600px!important;');
            }

            if (request['first_call'] == true)
                that.call_type = 'toggle';
            else
                that.call_type = 'un-toggle';


            if (that.collection_resource.search_text_val != '' && that.collection_resource.search_text_val != 0) {
                $.each(that.collection_resource.markerHandlerArray, function (index, object) {
                    object.initMarkerIndexTranscript('index');
                });
            }
            if (!that.mcustomscroll_init_index) {
                $(".index_point_container").mCustomScrollbar('destroy');
                $(".index_point_container").mCustomScrollbar({
                        callbacks: {
                            whileScrolling: function () {
                                if ($(".index_point_container").is(':hover')) {
                                    that.scroll_manager('index', that.selected_index, this.mcs.draggerTop, this.mcs.topPct);
                                }
                            },
                            onTotalScroll: function () {
                                $(".index_point_container").mCustomScrollbar("scrollTo", this.mcs.top + 30);
                            },
                            onTotalScrollBack: function () {
                                $(".index_point_container").mCustomScrollbar("scrollTo", 30);
                            }
                        }
                    }
                );
            } else {
                $(".index_point_container").mCustomScrollbar('update');
            }
            that.mcustomscroll_init_index = true;
        }

        $('.tab_loader_index').addClass('d-none');
        $('.tab_loader_index').removeClass('d-inline-block');
        if (request['sliding'] == 'timeline') {
            that.to_index_transcript_point($('.index_timeline.dark-orange').data());
        }
        setTimeout(function () {
            that.index_loading_call = {}
            that.index_number_of_ajax_calls--;
            if (that.index_number_of_ajax_calls < 0) {
                that.index_number_of_ajax_calls = 0;
            }
            if (that.transcript_number_of_ajax_calls <= 0) {
                $('.index #overlay-counters').addClass('d-none');
            }
            $('.tab_loader_index').addClass('d-none');
            $('.tab_loader_index').removeClass('d-inline-block');
        }, 1300);

    };


    this.load_resource_transcript_init = function (first_call, sliding, page_number, page_type, movement, pass_multiple_calls, load_previous_next) {

        if (Object.keys(that.transcript_loading_call).length === 0 || (pass_multiple_calls && that.transcript_number_of_ajax_calls <= 3)) {
            $('.transcript #overlay-counters').removeClass('d-none');
            that.transcript_number_of_ajax_calls++;
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
                load_previous_next: load_previous_next,
                pass_multiple_calls: pass_multiple_calls
            };
            this.transcript_loading_call = that.app_helper.classAction($('.transcript-tab').data('template-url'), data, 'html', 'GET', '.transcript_point_inner_container', that, false);
        }
    };


    this.load_resource_transcript = function (response, container, request) {


        if (response && (response.includes('transcript_time') || response.includes('file_transcript'))) {

            if (request['movement'] == 'up' && request['page_type'] == 'previous_page') {
                $('.transcript_point_container .next_page_type').remove();
                $('.transcript_point_container .current_page_type').addClass('next_page_type').removeClass('current_page_type');
                $('.transcript_point_container .previous_page_type').addClass('current_page_type').removeClass('previous_page_type');
            } else if (request['movement'] == 'down' && request['page_type'] == 'next_page') {
                $('.transcript_point_container .previous_page_type').remove();
                $('.transcript_point_container .current_page_type').addClass('previous_page_type').removeClass('current_page_type');
                $('.transcript_point_container .next_page_type').addClass('current_page_type').removeClass('next_page_type');
            }
            if (request['sliding'] == 'timeline' || request['sliding'] == 'marker_button' || request['sliding'] == 'clear') {
                $(container).html('');
            }

            if (request['page_type'] == 'current_page') {
                $(container).append(response);
                if (request['load_previous_next'] == true && !response.includes('no-access') && that.current_selected_total_page('transcript', that.selected_transcript) > 0) {
                    setTimeout(function () {
                        that.load_resource_transcript_init(request['first_call'], 'no', parseInt(request['page_number'], 10) - 1, 'previous_page', 'no', request['pass_multiple_calls']);
                        that.load_resource_transcript_init(request['first_call'], 'no', parseInt(request['page_number'], 10) + 1, 'next_page', 'no', request['pass_multiple_calls']);
                    }, 500);
                }
            } else if (request['page_type'] == 'previous_page') {
                $(container).prepend(response);
            } else if (request['page_type'] == 'next_page') {
                $(container).append(response);
            }

            if (that.from_playlist) {
                $('.transcript_point_container').attr('style', 'height:' + ($('.two_col_custom').height()) + 'px!important;max-height:600px!important;');
            } else {
                $('.transcript_point_container').attr('style', 'height:' + ($('.two_col_custom').height()) + 'px!important;max-height:600px!important;');
            }

            if (request['first_call'] == true)
                that.call_type = 'toggle';
            else
                that.call_type = 'un-toggle';

            that.initialize();
            if (that.collection_resource.search_text_val != '' && that.collection_resource.search_text_val != 0) {
                $.each(that.collection_resource.search_text_val, function (identifier) {
                    that.collection_resource.markerHandlerArray[identifier].initMarkerIndexTranscript('transcript');
                });
            }
            activate_export($('#file_' + that.cuePointType + '_select').val());
            if (!that.mcustomscroll_init) {
                $(".transcript_point_container").mCustomScrollbar('destroy');
                $(".transcript_point_container").mCustomScrollbar({
                        callbacks: {
                            whileScrolling: function () {
                                if ($(".transcript_point_container").is(':hover')) {
                                    that.scroll_manager('transcript', that.selected_transcript, this.mcs.draggerTop, this.mcs.topPct);
                                }
                            },
                            onTotalScroll: function () {
                                $(".transcript_point_container").mCustomScrollbar("scrollTo", this.mcs.top + 30);
                            },
                            onTotalScrollBack: function () {
                                $(".transcript_point_container").mCustomScrollbar("scrollTo", 30);
                            }
                        }
                    }
                );
            } else {
                $(".transcript_point_container").mCustomScrollbar('update');
            }
            that.mcustomscroll_init = true;
        }

        $('.tab_loader_transcript').addClass('d-none');
        $('.tab_loader_transcript').removeClass('d-inline-block');
        if (request['sliding'] == 'timeline') {
            that.to_index_transcript_point($('.transcript_timeline.dark-orange').data());
        }
        if (that.collection_resource.search_text_val != '' && that.collection_resource.search_text_val != 0) {
            $.each(that.collection_resource.markerHandlerArray, function (index, object) {
                object.initMarkerIndexTranscript('index');
            });
        }

        setTimeout(function () {
            that.transcript_loading_call = {}
            that.transcript_number_of_ajax_calls--;
            if (that.transcript_number_of_ajax_calls < 0) {
                that.transcript_number_of_ajax_calls = 0;
            }
            if (that.transcript_number_of_ajax_calls <= 0) {
                $('.transcript #overlay-counters').addClass('d-none');
            }
        }, 1000);
    }
    ;


    this.to_index_transcript_point = function (data) {
        $('#' + data.type + '-tab').click();
        $('.highlight-marker').removeClass('current-active-index');
        $(".highlight-marker").removeClass('current');

        if (typeof $('#' + data.type + '_timecode_' + data.point) != 'undefined') {
            that.scroll_to_point(data.type, '#' + data.type + '_timecode_' + data.point)
        }
    };

    this.scroll_to_point = function (type, element) {
        setTimeout(function () {
            $('.' + type.toLowerCase() + '_point_container').mCustomScrollbar("scrollTo", element);
        }, 2000);
    }


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
                if (type == 'index') {
                    let information = that.pages_be_shown(that.index_page_number, movement, type, total_pages, 'scroll', '.' + type + '_point_container', current_percentage);
                    if (information) {
                        that.call_index_pages(information);
                    }
                } else {
                    let information = that.pages_be_shown(that.transcript_page_number, movement, type, total_pages, 'scroll', '.' + type + '_point_container', current_percentage);
                    if (information) {
                        that.call_index_pages(information);
                    }
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
        $('#' + that.cuePointType + '_update_btn').click(function () {
            current = $('#file_' + that.cuePointType + '_select');
            $('#new_file_' + that.cuePointType).attr('action', that.uploadUrl + '/' + current.val());
            $('#' + that.cuePointType + '_upload_title').html('Update "' + current.text() + '" ' + capitalize(that.cuePointType));
            $('#file_' + that.cuePointType + '_title').val(current.text());
            $('#file_' + that.cuePointType + '_language')[0].selectize.setValue($('.file_' + that.cuePointType + '_' + current.val()).data().language);
            $('#file_' + that.cuePointType + '_is_public')[0].selectize.setValue($('.file_' + that.cuePointType + '_' + current.val()).data().public.toString());
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
            $('.upload_' + that.cuePointType + '_btn').unbind("click");
        });
    };
    let activateDeletePopup = function () {
        $('#delete_' + that.cuePointType).click(function () {
            $('#modalPopupTitle').html('Delete ' + capitalize(that.cuePointType));
            currentInfo = $('#file_' + that.cuePointType + '_select');
            $('#modalPopupBody').html('Are you sure you want to delete this ' + capitalize(that.cuePointType) + ' information ("' + currentInfo.text() + '") for this file? This operation cannot be undone.');
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
            } else if ($('#360_player').length > 0) {
                player_widget.seek(currentTime);
                player_widget.play();
            } else {
                player.setCurrentTime(currentTime);
                player.play();
            }
        }, true)
    };

    let activatePoints = function (call_type) {
        let selected_element = '.file_' + that.cuePointType + '_' + $('#file_' + that.cuePointType + '_select').val();

        $(selected_element).removeClass('d-none');
        $('.' + that.cuePointType + '_' + $('#file_' + that.cuePointType + '_select').val()).removeClass('d-none');
        $('.file_' + that.cuePointType + '_' + $('#file_' + that.cuePointType + '_select').val()).toggleClass('selected_' + that.cuePointType + 'file');
        $('#file_' + that.cuePointType + '_select').unbind('change');
        $('#file_' + that.cuePointType + '_select').change(function () {
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

            that.collection_resource.init_scoll(that.cuePointType, that.collection_resource.currentTime, true);
            try {
                if (typeof that.collection_resource.events_tracker != 'undefined')
                    that.collection_resource.events_tracker.track_tab_hits(that.cuePointType, true);
            } catch (e) {
                e;
            }
            activate_export($('#file_' + that.cuePointType + '_select').val());
            if (that.collection_resource.search_text_val != '' && that.collection_resource.search_text_val != 0) {
                $.each(that.collection_resource.markerHandlerArray, function (_index, object) {
                    object.currentIndex = 1;
                    $('.current_location').text(object.currentIndex)
                });
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
        $(".text-danger").html("");
        if (Object.size(result.errors) > 0) {
            $('#progress .progress-bar').css("width", "0%");
            $('.upload_' + that.cuePointType + '_btn').html("Upload " + capitalize(that.cuePointType)).prop("disabled", false);
            for (cnt in result.errors) {
                $('.' + cnt).html(result.errors[cnt]);
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
    }
}
