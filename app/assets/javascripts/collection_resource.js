function CollectionResource() {

    /**
     * CollectionResource Management
     *
     * @author Nouman Tayyab <nouman@weareavp.com>
     *
     */
    var file_access = true;
    var selfCR = this;
    selfCR.markerHandlerArrayDescription = {};
    selfCR.markerHandlerIT = {};
    var recorded_transcript = [];
    var recorded_index = [];
    var previousTime = 0;
    selfCR.currentTime = 0;
    selfCR.app_helper = {};
    selfCR.edit_description = 0;
    selfCR.search_text_val = 0;
    selfCR.resource_file_id = 0;
    selfCR.player_widget = null;
    selfCR.track_params = null;
    selfCR.has_loaded = false;
    selfCR.player_time = 0;
    selfCR.events_tracker = {};
    selfCR.from_playlist = false;
    selfCR.playlist_info = {};
    selfCR.embed = false;
    selfCR.selected_index = 0;
    selfCR.current_marker_index = null;
    selfCR.selected_transcript = 0;
    selfCR.index_page_wise_count = {};
    selfCR.transcript_page_wise_count = {};
    selfCR.index_hits_count = {};
    selfCR.transcript_hits_count = {};
    selfCR.transcript_time_wise_page = {};
    selfCR.index_time_wise_page = {};

    selfCR.total_transcript_wise = {};
    selfCR.total_index_wise = {};

    selfCR.index_file_count = 0;
    selfCR.transcript_file_count = 0;
    selfCR.auto_loading_inprogress = false;

    const clearKeyWords = function (keyword) {
        keyword = keyword.replace(/[\/\\()|'"*:^~`{}]/g, '');
        keyword = keyword.replace(/]/g, '');
        keyword = keyword.replace(/[[]/g, '');
        keyword = keyword.replace(/[{}]/g, '');
        return keyword;
    }

    const searchFieldBinding = function () {
        document_level_binding_element("#search_text", 'keypress', function (e) {
            if (e.which == 13) {
                if ($(this).val().trim() != '') {
                    let query = 'keywords[]=' + $(this).val().trim();
                    let link = window.location.href;
                    if (!link.includes('?')) {
                        link += '?';
                    }
                    link = link + '&' + query;
                    window.location = link;
                }
            }
        });
    }

    this.initializeDetail = function (search_text_val, selected_index, selected_transcript, edit_description, embed, resource_file_id, track_params) {
        selfCR.track_params = track_params;
        selfCR.resource_file_id = resource_file_id;
        selfCR.app_helper = new App();
        selfCR.edit_description = edit_description;
        selfCR.embed = embed;
        load_resource_details(embed);
        selfCR.selected_index = selected_index;
        selfCR.selected_transcript = selected_transcript;
        $('.index-trance-checkbox').prop('checked', false);
        selfCR.search_text_val = jQuery.parseJSON(search_text_val);
        initPlayer();
        initCopyLink();
        searchFieldBinding();
        fileWiseCountFunc();
        if (selfCR.search_text_val != '' && selfCR.search_text_val != 0) {
            $.each(selfCR.search_text_val, function (identifier, keyword) {
                keyword = clearKeyWords(keyword);
                selfCR.markerHandlerIT[identifier] = new MarkerHandlerIndexTranscript(identifier, keyword);
                selfCR.markerHandlerIT[identifier].collection_resource = selfCR;
                selfCR.markerHandlerIT[identifier].initialize();
            });
        }
        selfCR.indexes = new IndexTranscript();
        selfCR.indexes.setup_prerequisites('index', selfCR.selected_index, selfCR, selfCR.embed, selfCR.from_playlist);
        selfCR.indexes.selected_index = selfCR.selected_index;
        selfCR.indexes.selected_transcript = selfCR.selected_transcript;
        selfCR.indexes.initialize(selfCR.selected_index);
        if (parseInt(selfCR.index_file_count, 10) > 0) {
            selfCR.indexes.first_time_index_call();
        }

        selfCR.transcripts = new IndexTranscript();
        selfCR.transcripts.setup_prerequisites('transcript', selfCR.selected_transcript, selfCR, selfCR.embed, selfCR.from_playlist);
        selfCR.transcripts.selected_index = selfCR.selected_index;
        selfCR.transcripts.selected_transcript = selfCR.selected_transcript;
        selfCR.transcripts.initialize(selfCR.selected_transcript);
        if (parseInt(selfCR.transcript_file_count, 10) > 0) {
            selfCR.transcripts.first_time_transcript_call();
        }

        // move Marker list to top related div after created marker occurrence using using later updated variable session[:count][:index_count]s, @description_count and session[:count][:transcript_count]s
        $('.marker_list_hanlder_custom').html($('.marker_list_hanlder_custom_tmp').html());
        $('.marker_list_hanlder_custom_tmp').html('');
        let type_current = 'description';
        if (window.location.pathname.substr(window.location.pathname.lastIndexOf('/') + 1) && !$.inArray(type_current, ['transcript', 'description', 'index']) <= 0) {
            type_current = window.location.pathname.substr(window.location.pathname.lastIndexOf('/') + 1);
        }
        show_marker_hanlders(type_current);

    };

    const detailsPageBinding = function () {
        bindingElement('#collection_resource_custom_unique_identifier', 'keyup', function () {
            let element_that = this;
            setTimeout(function () {
                if ($(element_that).val().match(/[/?!*'()"\\;:@&=+\]\[$,/?%# ]/)) {
                    selfCR.app_helper.show_modal_message('Invalid Value', ' You provided an invalid character in your custom unique identifier.', 'danger');
                    $(element_that).val($(element_that).val().replace(/[/?!*'()\\;:@&=+\]\[$,/?%# ]/g, ''));
                }
            }, 200);
        }, false);
    };

    this.initializePlayer = function () {
        selfCR.app_helper = new App();
        initPlayer();
    };

    this.handlecallback = function (response, container, requestData) {
        try {
            eval('this.' + requestData.action + '(response,container,requestData)');
        } catch (err) {
            console.log(err);
        }
    };

    this.show_counts_tabs = function (response) {

        try {
            if (response.description_count['total']) {
                $('.description_count_tab').text(response.description_count['total']);
                $('.description_count_tab').removeClass('d-none');
            }
        } catch (err) {

        }
    };

    const show_counts_tabs = function () {
        let data = {
            action: 'show_counts_tabs'
        };
        selfCR.app_helper.classAction($('#show_counts_tabs').data('url'), data, 'JSON', 'GET', '', selfCR, false);
    };

    this.fileWiseCount = function (response) {
        try {
            $.each(response['count_file_wise'], function (index, object) {
                let total_index = 0
                let total_transcript = 0
                if (parseInt(object['total-transcript'], 10)) {
                    total_transcript = parseInt(object['total-transcript'], 10)
                }

                if (parseInt(object['total-index'], 10)) {
                    total_index = parseInt(object['total-index'], 10)
                }

                $('.file_wise_count_' + index).text(total_transcript + total_index);
                if ((total_transcript + total_index) > 0)
                    $('.file_wise_count_' + index).removeClass('d-none');
            });
        } catch (err) {

        }
    };

    const fileWiseCountFunc = function () {
        let data = {
            action: 'fileWiseCount',
            search_text_val: selfCR.search_text_val,
        };
        selfCR.app_helper.classAction($('#file_wise_count').data('url'), data, 'JSON', 'POST', '', selfCR, false);
    };

    this.load_resource_details_template = function (response, container) {
        if (response.includes('view_edit_custom')) {
            $('.contact-description-tab').html(response);
            setTimeout(function () {
                desc_trans_index_call_complete();
                init_tinymce_for_element('.edit_collection_resource textarea.value_holder');
                show_counts_tabs();
                $('.edit_collection_resource .select_option.value_holder').selectize();
                /* Edit resource form */
                $('.edit_fields').click(function () {
                    $('body').css('overflow', 'hidden');
                    $('#form_edit_custom').addClass('open');
                });

                $('#form_edit_custom #modal-close').click(function () {
                    $('body').css('overflow', 'inherit');
                    $('#form_edit_custom').removeClass('open');
                });
                if (selfCR.edit_description == true || selfCR.edit_description == 'true') {
                    $('.edit_fields').click();
                }
            }, 100);
            setTimeout(function () {
                resourceSearchBar();
            }, 1000);
        }
    };

    const desc_trans_index_call_complete = function () {

        // move timeline bar to related div after creating bar and using later updated variable session[:count][:index_count]s
        $('.timeline-bar-parent-div').html($('.timeline-bar-parent-div-tmp').html());
        $('.timeline-bar-parent-div-tmp').html('');
        initTimeline();

        if (selfCR.from_playlist) {
            $('#view_edit_custom').attr('style', 'height:' + ($('.two_col_custom').height()) + 'px!important;max-height:550px!important;');
        } else {
            $('#view_edit_custom').attr('style', 'height:' + ($('.two_col_custom').height()) + 'px!important;max-height:550px!important;');

        }
        $('.mCustomScrollbar_description').mCustomScrollbar();

        initEvents();
        initCreateTranscription();
        selfCR.manageTabs(selfCR.edit_description);
        if (selfCR.search_text_val != '' && selfCR.search_text_val != 0) {
            $.each(selfCR.search_text_val, function (identifier, keyword) {
                keyword = clearKeyWords(keyword);
                selfCR.markerHandlerArrayDescription[identifier] = new MarkersHanlderDescription(identifier, keyword);
                selfCR.markerHandlerArrayDescription[identifier].initialize();
                selfCR.markerHandlerArrayDescription[identifier].collection_resource = selfCR;
            });
        }
        $('.loader-details').remove();
    };

    const load_resource_details = function (embed) {
        let data = {
            action: 'load_resource_details_template',
            tabs_size: $('.info_tabs').data('tabs-size'),
            search_size: $('.info_tabs').data('search-size'),
            embed: embed
        };
        data = jQuery.extend(data, collectionResource.playlist_info);
        selfCR.app_helper.classAction($('.info_tabs').data('template-url'), data, 'html', 'GET', '.info_tabs', selfCR, false);
    };

    const load_head_and_tombstone = function () {
        if ($('#heading_and_tombstone').length > 0) {
            let data = {
                action: 'load_head_and_tombstone_template'
            };
            selfCR.app_helper.classAction($('#heading_and_tombstone').data('template-url'), data, 'html', 'GET', '#heading_and_tombstone', selfCR, false);
        }
    };

    const initPlayer = function () {
        if (file_access) {
            if ($('#avalon_widget').length > 0) {
                var offsetTime = 0;
                var target_domain = $('#avalon_widget').data().domain;
                player_widget = function (c, params) {
                    var f = $('#avalon_widget');
                    var command = params || {};
                    command['command'] = c;
                    f.prop('contentWindow').postMessage(command, target_domain);

                };

                window.addEventListener('message', function (event) {
                    selfCR.currentTime = event.data.currentTime;
                    time_scroll_mover(event.data.currentTime);
                    var command = event.data.command;
                    if (command == 'currentTime')
                        offsetTime = event.data.currentTime;
                    previousTime = event.data.currentTime;
                });

                setInterval(function () {
                    player_widget('get_offset');
                }, 500);
                if (selfCR.player_time > 0) {
                    player_widget('set_offset', {'offset': currentTime});
                    player_widget('play');
                }

            } else if ($('#360_player').length > 0) {
                player_widget = jwplayer('360_player').setup({
                    playlist: [{
                        file: $('#360_player').data('url'),
                        tracks: $('#360_player').data('tracks'),
                        mediaid: 'AgqYcfAT',
                        stereomode: 'monoscopic',
                        image: $('#360_player').data('poster'),
                        autostart: window.location.href.indexOf('auto_play') > 0
                    }]
                });
                player_widget.on('error', function (_event) {
                    let confirm = window.confirm("Media file source not found or expired. Reload the page? Or contact organization admin.");
                    if (confirm == true) {
                        window.location.reload();
                    }
                });
                player_widget.on('complete', function (_event) {
                    if ($('.listings_files.my-slide').nextAll() && $('.listings_files.my-slide').nextAll().length > 0) {
                        play_next_file();
                    } else if ($('.box.now-playing.playlist_resource_single').nextAll() && $('.box.now-playing.playlist_resource_single').nextAll().length > 0) {
                        play_next_resource();
                    }
                });
                player_widget.on('time', function (event) {
                    selfCR.currentTime = event.currentTime;
                    // when end_time is elapsed, pause this video and jump to next
                    time_scroll_mover(event.currentTime);

                    if (selfCR.end_time != NaN && selfCR.end_time != undefined && event.currentTime >= selfCR.end_time && selfCR.end_time > 0) {
                        // pause this video and jump to next
                        player_widget.pause();
                        if (collectionResource.playlist_info.playlist_view_type == 'true') {
                            if ($('.listings_files.my-slide').nextAll() && $('.listings_files.my-slide').nextAll().length > 0) {
                                play_next_file();
                            } else if ($('.box.now-playing.playlist_resource_single').nextAll() && $('.box.now-playing.playlist_resource_single').nextAll().length > 0) {
                                play_next_resource();
                            }
                        }
                    }

                    previousTime = event.currentTime;
                });
                player_widget.on('ready', function () {
                    shareTimeUrl(player_widget.getCurrentTime(), $('#share_link').val());
                    if (window.location.href.indexOf('auto_play') > 0) {
                        let location = window.location.href;
                        location = location.replace('auto_play=true', '').replace('?&', '?').replace('&&', '&');
                        window.history.replaceState({}, 'auto_play=true', location);
                        player_widget.seek(0).play();
                    }
                    if (selfCR.player_time > 0) {
                        player_widget.seek(selfCR.player_time).play();
                    }
                })
            } else {
                meJsFeatures = ['playpause', 'current', 'progress', 'duration', 'volume', 'tracks', 'fullscreen', 'autoplay'];
                if ($('#player source').length > 1) {
                    meJsFeatures.push('quality');
                }
                selfCR.player_widget = player_widget = $('#player').mediaelementplayer({
                    features: meJsFeatures,
                    success: function (mediaElement, domObject) {
                        $('.video-placeholder').addClass('hovered');
                        shareTimeUrl(mediaElement.currentTime, $('#share_link').val());
                        mediaElement.addEventListener('timeupdate', function (e) {

                            time_scroll_mover(mediaElement.currentTime);
                            selfCR.currentTime = mediaElement.currentTime;
                            // when end_time is elapsed, pause this video and jump to next
                            if (selfCR.end_time != NaN && selfCR.end_time != undefined && mediaElement.currentTime >= selfCR.end_time && selfCR.end_time > 0) {
                                // pause this video and jump to next
                                mediaElement.pause();
                                if (collectionResource.playlist_info.playlist_view_type == 'true') {
                                    if ($('.listings_files.my-slide').nextAll() && $('.listings_files.my-slide').nextAll().length > 0) {
                                        play_next_file();
                                    } else if ($('.box.now-playing.playlist_resource_single').nextAll() && $('.box.now-playing.playlist_resource_single').nextAll().length > 0) {
                                        play_next_resource();
                                    }
                                }
                            }

                            previousTime = mediaElement.currentTime;
                        }, false);

                        let first_play = true;

                        mediaElement.addEventListener('playing', function () {
                            $('.video-placeholder').removeClass('hovered');
                            if (first_play) {
                                setTimeout(function () {
                                    $('.video-placeholder').removeClass('youtube');
                                    $('.video-placeholder').removeClass('vimeo');
                                }, 3000);

                                first_play = false;
                            }
                        });

                        mediaElement.addEventListener('pause', function () {
                            $('.video-placeholder').addClass('hovered');
                        });

                        mediaElement.addEventListener('ended', function (e) {
                            // for new UI design
                            if ($('.listings_files.my-slide').nextAll() && $('.listings_files.my-slide').nextAll().length > 0) {
                                play_next_file();
                            } else if ($('.box.now-playing.playlist_resource_single').nextAll() && $('.box.now-playing.playlist_resource_single').nextAll().length > 0) {
                                play_next_resource();
                            }
                        }, false);
                        if (window.location.href.indexOf('auto_play') > 0) {
                            mediaElement.play();

                            // generalizing the solution to replace state of History API; by preserving query parameters other than auto_play
                            var location = window.location.href;
                            location = location.replace('auto_play=true', '');
                            location = location.replace('?&', '?');
                            location = location.replace('&&', '&');

                            window.history.replaceState({}, 'auto_play=true', location);
                        }
                        if (selfCR.player_time > 0)
                            autoPlay(mediaElement);

                    },
                    error: function (_error) {
                        let confirm = window.confirm("Media file source not found or expired. Reload the page? Or contact organization admin.");
                        if (confirm == true) {
                            window.location.reload();
                        }
                    }
                });
            }
        }
        $('.carousel-wrap').removeClass('d-none');

        $(".carousel-wrap .mediacarousel").jCarouselLite({
            btnNext: ".next",
            btnPrev: ".prev",
            visible: 4,
            mouseWheel: (parseInt($('.carousel-wrap').data('filescount'), 10) > 3),
            circular: false,
            autoWidth: true,
            responsive: true,
        });

        if (parseInt($('.carousel-wrap').data('filescount'), 10) <= 4)
            $('.prev, .next').hide();

        scroll_mousewheel_playlist();
        setTimeout(function () {
            let sortorder = 0;
            if (parseInt($('.media.carousel-wrap').data('sortorder'), 10))
                sortorder = parseInt($('.media.carousel-wrap').data('sortorder'), 10);

            if (parseInt($('.carousel-wrap').data('filescount'), 10) > 3)
                selected_carosal(sortorder);
            scroll_mousewheel_playlist();

        }, 100);
        $(".video-side-list span").click(function () {
            $(".carousel-indicators").toggle();
        });

    };


    const time_scroll_mover = function (currentTime) {
        if ($('#index-tab').hasClass('active')) {
            if ($("#index-auto-scroll").prop("checked") && selfCR.selected_index > 0) {
                let start_time = parseFloat(selfCR.index_time_wise_page[selfCR.selected_index][selfCR.indexes.index_page_number].start_time);
                let end_time = parseFloat(selfCR.index_time_wise_page[selfCR.selected_index][selfCR.indexes.index_page_number].end_time);
                if (currentTime >= start_time && currentTime <= end_time) {
                    selfCR.init_scoll('index', currentTime);
                } else {
                    $.each(selfCR.index_time_wise_page[selfCR.selected_index], function (index, time_wise) {
                        if (currentTime >= time_wise.start_time && currentTime <= time_wise.end_time) {
                            if (selfCR.indexes.index_page_number != time_wise.current_page) {
                                selfCR.indexes.specific_page_load('timeline', time_wise.current_page, true);
                                return false;
                            }
                        }
                    });
                }

            }
        } else if ($('#transcript-tab').hasClass('active')) {
            if ($("#transcript-auto-scroll").prop("checked") && selfCR.selected_transcript > 0) {
                let start_time = parseFloat(selfCR.transcript_time_wise_page[selfCR.selected_transcript][selfCR.transcripts.transcript_page_number].start_time);
                let end_time = parseFloat(selfCR.transcript_time_wise_page[selfCR.selected_transcript][selfCR.transcripts.transcript_page_number].end_time);
                if (currentTime >= start_time && currentTime <= end_time) {
                    selfCR.init_scoll('transcript', currentTime);
                } else {
                    $.each(selfCR.transcript_time_wise_page[selfCR.selected_transcript], function (index, time_wise) {
                        if (currentTime >= time_wise.start_time && currentTime <= time_wise.end_time) {
                            if (selfCR.transcripts.transcript_page_number != time_wise.current_page) {
                                selfCR.transcripts.specific_page_load_transcript('timeline', time_wise.current_page);
                                return false;
                            }
                        }
                    });
                }
            } else {
                $('.transcript_time').removeClass('active');
            }
        }
    }

    const play_next_resource = function () {
        $.each($('.box.now-playing.playlist_resource_single').nextAll(), function () {
            if ($(this).hasClass('canplay') && $(this).hasClass('not-playing')) {
                window.location = $(this).find('.title.can-play-resource').attr('href');
                return false;
            }
        });

    };

    const play_next_file = function () {
        $.each($('.listings_files.my-slide').nextAll(), function () {
            if ($(this).hasClass('list_can_access') && !$(this).hasClass('my-slide')) {
                window.location = $(this).find('.playlist-item.can-play').data('media-url');
                return false;
            }
        });
    };

    let scroll_mousewheel_playlist = function () {
        $('.carousel-wrap').unbind('mousewheel DOMMouseScroll');
        $('.carousel-wrap').bind('mousewheel DOMMouseScroll', function (e) {
            var scrollTo = null;
            if (e.type == 'mousewheel') {
                scrollTo = (e.originalEvent.wheelDelta * -1);
            } else if (e.type == 'DOMMouseScroll') {
                scrollTo = 40 * e.originalEvent.detail;
            }
            if (scrollTo) {
                e.preventDefault();
                $(this).scrollTop(scrollTo + $(this).scrollTop());
            }
        });
    };

    let selected_carosal = function (number_of_movies) {
        var counter = 1;
        var interval = setInterval(function () {
            if (counter < number_of_movies) {
                $('.next').click();
                counter++;
            } else {
                clearInterval(interval);
                counter++;
            }
        }, 300);

    };

    let autoPlay = function (mediaElement) {
        if (selfCR.player_time > 0) {
            mediaElement.setCurrentTime(selfCR.player_time);
        }

        // mediaElement.setMuted(true);
        // document.addEventListener('click', function () {
        //     player.setMuted(false);
        // });

        mediaElement.setAttribute('autoplay', 'true');
        $('.mejs__play').click();
        mediaElement.play();
    };

    let shareTimeUrl = function (currentTime, url) {

        $('.share_tabs').on('mouseup', function () {
            let active_tab = $(this).data('tabname');

            setTimeout(function () {
                if (active_tab == 'public_access_url_custom') {
                    selfCR.setPeriodTimePeriod($('#public_access_time_period').data('daterangepicker').startDate.format('MM-DD-YYYY'), $('#public_access_time_period').data('daterangepicker').endDate.format('MM-DD-YYYY'));
                }
                checkAndCreateUrl();
            }, 500);
        });

        $('.start_time_checkbox').click(function () {
            checkAndCreateUrl();
            if ($(this).prop("checked") === true) {
                if ($('#start_time_share').val() == '')
                    $('#start_time_share').val(secondsToHuman(currentTime));
                $('.video-start-time').removeAttr('disabled');

            } else {
                $('.video-start-time').attr('disabled', 'disabled');
                $('#share_link').val();
            }
        });
        $('.video-start-time').keyup(function () {
            checkAndCreateUrl();

        });
    };

    let checkAndCreateUrl = function () {
        let active_tab = $($('.share_tabs.active')[0]).data('tabname');
        let current_value = '';
        let url;
        if ($('.' + active_tab + ' .share_value').prop('tagName').toLowerCase() == 'textarea') {
            current_value = $('.' + active_tab + ' .share_value').text();
        } else {
            current_value = $('.' + active_tab + ' .share_value').val();
        }

        let urls = selfCR.app_helper.findUrls(current_value);

        if (typeof urls != "undefined" && urls.length > 0) {
            url = urls[0];

            let time = $('#start_time_share').val();
            let seconds = humanToSeconds(time);
            let createURL = true;

            if (!isNaN(time)) {
                $('#start_time_share').val(secondsToHuman(time));
            } else if (isNaN(seconds)) {
                $('#start_time_share').val('00:00:00');
                createURL = false;
            }

            let shareTime = humanToSeconds($('#start_time_share').val());
            let url_raw = selfCR.app_helper.getUrlParameter(url);
            let only_url = url_raw[1];
            let get_params = url_raw[0];
            params = 0;
            let all_params = '';
            let counter = 0;
            $.each(get_params, function (key, value) {
                if (key.toString() != 't' && key.toString() != 'media') {
                    if (counter != 0) {
                        all_params = all_params + '&';
                    }
                    all_params = all_params + key.toString() + '=' + value;
                    counter++;
                }
            });
            if (all_params != '' && $('.start_time_checkbox').prop("checked") === true) {
                all_params = all_params + '&'
            }

            let final_link = '';
            let shareLink = '';
            if (createURL && shareTime > 0 && $('.start_time_checkbox').prop("checked") === true) {
                shareLink = only_url + '?' + all_params + 'media=' + selfCR.resource_file_id + '&t=' + shareTime;
            } else {
                shareLink = only_url + '?' + all_params;
            }

            switch (active_tab) {
                case 'share_link_custom':
                    final_link = shareLink;
                    break;
                case 'embed_video_custom':
                    final_link = '<iframe src="' + shareLink + '" height="400" width="1200" style="width: 100%;" allow="fullscreen"></iframe>';
                    break;
                case 'embed_resource_custom':
                    final_link = '<iframe src="' + shareLink + '" height="400" width="1200" style="width: 100%;" allow="fullscreen"></iframe>';
                    break;
                case 'embed_resource_media_player':
                    final_link = '<iframe src="' + shareLink + '" height="400" width="1200" style="width: 100%;" allow="fullscreen"></iframe>';
                    break;
                case 'public_access_url_custom':
                    final_link = shareLink;
                    break;
            }
            if ($('.' + active_tab + ' .share_value').prop('tagName').toLowerCase() == 'textarea') {
                $('.' + active_tab + ' .share_value').text(final_link);
            } else {
                $('.' + active_tab + ' .share_value').val(final_link);
            }
        }
    };

    this.init_scoll = function (type, currentTime, trigger_refresh) {
        if (typeof trigger_refresh == 'undefined') {
            trigger_refresh = false;
        }
        if ($("#" + type + "-auto-scroll").prop("checked") && parseInt(currentTime, 10) > 0) {
            if ($('.' + type + '_time_start_' + parseInt(currentTime, 10)).length > 0 && trigger_refresh == false) {
                do_scroll(type, currentTime);
            } else if (parseFloat(currentTime) - parseFloat(previousTime) > 0.75 || parseFloat(currentTime) - parseFloat(previousTime) < -0.75 || trigger_refresh == true) {
                setTimeout(function () {
                    var allAttributes = $('.' + type + '_time').map(function () {
                        return $(this).data('' + type + '_timecode');
                    }).get();
                    if (currentTime > Math.max.apply(null, allAttributes)) {
                        do_scroll(type, Math.max.apply(null, allAttributes));
                    } else {
                        var i;
                        for (i = parseInt(currentTime, 10); i != 0; i--) {
                            if ($('.' + type + '_time_start_' + parseInt(i, 10)).length > 0) {

                                do_scroll(type, i);
                                break;
                            }
                        }
                    }
                }, 50);
            }
        }
    }
    ;

    const do_scroll = function (type, currentTime) {
        try {
            var selected_point = parseInt($('#file_' + type + '_select').val(), 10);
            if (selected_point > 0) {
                if (type == 'transcript') {
                    if (typeof recorded_transcript[selected_point] == 'undefined') {
                        recorded_transcript[selected_point] = [];
                    }

                    if (!recorded_transcript[selected_point].includes(parseInt(currentTime, 10))) {
                        recorded_transcript[selected_point].push(parseInt(currentTime, 10));
                    }
                    setTimeout(function () {
                        let pointToScroll = $('.' + type + '_time_start_' + parseInt(currentTime, 10));
                        selfCR.transcripts.scroll_to_point(type, '.' + type + '_time_start_' + parseInt(currentTime, 10));
                    }, 50);

                } else {
                    if (typeof recorded_index[selected_point] == 'undefined') {
                        recorded_index[selected_point] = [];
                    }
                    if (!recorded_index[selected_point].includes(parseInt(currentTime, 10))) {
                        recorded_index[selected_point].push(parseInt(currentTime, 10));
                    }
                    setTimeout(function () {
                        selfCR.indexes.scroll_to_point(type, '.' + type + '_time_start_' + parseInt(currentTime, 10));
                    }, 50);
                }
            }
        } catch (e) {
            console.log(e);
        }
    };

    $(document).on('click', '.player-item', function (event) {
        if (!$(this).hasClass('locked'))
            window.location.href = $(this).attr('data-media-url');
    });

    const initEvents = function () {
        $('.edit_collection_resource').on('submit', function (e) {
            $('.form-control.date.value_holder').each(function (index, value) {
                var regExFull = /^\d{4}-\d{2}-\d{2}$/;
                var regExYm = /^\d{4}-\d{2}$/;
                var regExy = /^\d{4}$/;
                value_string = $.trim($(value).val());
                if (!value_string.match(regExFull) && !value_string.match(regExYm) && !value_string.match(regExy)) {
                    jsMessages('danger', 'One ore more date(s) given are invalid. Allowed date formats are ( yyyy-mm-dd or yyyy-mm or yyyy)');
                    e.preventDefault();
                }
            });
        });

        $('.addmore-row').each(function (index, element) {
            if ($(element).data().is_repeatable == false && $(element).parent('dt').next().find('.remove-field').length > 1) {
                $(element).hide();
            }
        });
        $('.moreclick').on('click', function () {
            $('.custom-modal-normal').hide();
            $('#' + $(this).data('id')).show();
        });

        $('.custom-modal-normal .btn-close').on('click', function () {
            $('.custom-modal-normal').hide();
        });


        $('.addmore-row').click(function (event) {
            if ($(this).data().is_repeatable == false) {
                $(this).hide();
            }
            var new_html = $(this).parents('.current-parent').find('.row_clone').html();
            let identifier = Math.random().toString(36).substring(2, 15);
            if ($(this).data('type') == 'editor') {
                new_html = new_html.replace('add_wanted_class', ' apply_froala_editor tinymce apply_froala_editor_' + identifier);
            }

            let unique_identifier = 'select_option_new_added' + identifier;
            if (new_html.includes("select_option")) {
                new_html = new_html.replace('select_option', ' select_option_new_added ' + unique_identifier);
            }

            $(this).parents('.current-parent').find('.single_row_dynamic_form').append(new_html);
            $('.remove-field').click(function (event) {
                $(this).parents('.current-parent').find('.addmore-row').show();
                $(this).parents('.parent_of_each_row').remove();
            });
            $('.tokenMaker').tagsinput({
                tagClass: 'big'
            });
            $('.bootstrap-tagsinput input').attr('style', 'width: 200px;');

            if ($(this).data('type') == 'editor') {
                init_tinymce_for_element('.apply_froala_editor_' + identifier);
            }
            setTimeout(function () {
                $('.' + unique_identifier).selectize();
            }, 50);
        });
        $.each($('.row_clone').find('select.cloner'), function (single_index, single_element) {
            if (single_element.selectize) {
                single_element.selectize.destroy();
            }
        });
        $('.remove-field').click(function (event) {
            $(this).parents('.current-parent').find('.addmore-row').show();
            $(this).parents('.parent_of_each_row').remove();
        });
        setTimeout(function () {
            $('.tokenMaker').tagsinput({
                tagClass: 'big'
            });
            $('.bootstrap-tagsinput input').attr('style', 'width: 200px;');
        }, 200);

        // Manage Search bar on the resource page and the keywords
        resourceSearchBar();
        $(window).scroll(function () {
            manageSearchBoxPosition();
        });


    };
    manageSearchBoxPosition = function () {
        if ($('.search_details_bar .sticky-wrapper').hasClass('is-sticky')) {
            $('.search_details_bar .col-md-12').addClass('sticked');
        } else {
            $('.search_details_bar .col-md-12').removeClass('sticked');
        }


    };

    this.track_tab_hits = function (tabType) {
        if ($('#file_' + tabType + '_select').length > 0) {
            let index_transc = $('#file_' + tabType + '_select').selectize();
            let selectize = index_transc[0].selectize;
            selfCR.events_tracker.track_hit(tabType, selectize.getValue());
        }
    };

    const active_transcript_index = function (type) {
        return parseInt($('#file_' + type + '_select').val(), 10);
    }
    const transcript_scroll = function () {
        selfCR.transcripts.index_scroll('transcript', active_transcript_index('transcript'));
    };

    const index_scroll = function () {
        selfCR.indexes.index_scroll('index', active_transcript_index('index'));
    };

    this.default_active_tab = function () {
        let tabType = window.location.pathname.substr(window.location.pathname.lastIndexOf('/') + 1);
        if (!$.inArray(tabType, ['transcript', 'description', 'index']) >= 0) {
            $('#description-tab').click();
        }
    }

    this.manageTabs = function (edit_description) {
        let tabType = window.location.pathname.substr(window.location.pathname.lastIndexOf('/') + 1);
        if (collectionResource.from_playlist == true) {
            tabType = $('#resourceTab .nav-link.active.show').data('tab');
        }

        $('.single_term_handler').addClass('d-none');
        $('.single_term_handler').removeClass('open');

        if (edit_description) {
            $('.edit_fields').click();
            window.history.replaceState({}, document.title, window.location.pathname);
            return true;
        } else if (tabType == 'transcript') {
            $('#transcript-tab').click();
        } else if (tabType == 'index') {
            $('#index-tab').click();
        }
        if ($.inArray(tabType, ['transcript', 'description', 'index']) < 0)
            tabType = 'description';
        if (tabType == 'description') {

        }

        if (selfCR.search_text_val != '' && selfCR.search_text_val != 0) {
            $.each(selfCR.search_text_val, function (identifier, keyword) {
                if (!selfCR.from_playlist) {
                    $(".title_resource_custom").mark(keyword, {
                        "element": "div",
                        "className": "highlight-marker mark d-inline",
                        "caseSensitive": false,
                        "separateWordSearch": false
                    });
                }
            });
        }


        if (tabType == 'transcript') {
            transcript_scroll();
        } else if (tabType == 'index') {
            index_scroll();
        }
        $('.single_term_handler.' + tabType).removeClass('d-none');
        $('.single_term_handler.' + tabType).addClass('open');

        $('#resourceTab a').unbind('click');
        $('#resourceTab a').click(function () {
            let tabType = window.location.pathname.substr(window.location.pathname.lastIndexOf('/') + 1);
            let currentTab = $(this).data().tab;
            try {
                if (!$(this).hasClass('active')) {
                    selfCR.events_tracker.track_tab_hits(currentTab);
                }
            } catch (e) {
                e;
            }


            let append_params = '?';
            $.each(selfCR.app_helper.getUrlParamRepeatable(window.location.href)[0], function (index, single_obejct) {
                if (typeof single_obejct != 'undefined') {
                    append_params += single_obejct + '&';
                }
            });

            if (collectionResource.from_playlist == false) {
                if ($.inArray(tabType, ['transcript', 'description', 'index']) >= 0)
                    window.history.replaceState({}, document.title, window.location.pathname.replace(/\/[^\/]*$/, '/' + currentTab) + append_params);
                else
                    window.history.replaceState({}, document.title, window.location.pathname + '/' + currentTab + append_params);
            }

            if (tabType == 'index') {
                index_scroll('index');
            }

            if (tabType == 'transcript') {
                transcript_scroll('transcript');
            }
            $('.search-result-bottom').removeClass('open');
            if (selfCR.search_text_val != '' && selfCR.search_text_val != 0) {
                $.each(selfCR.markerHandlerArrayDescription, function (_index, object) {
                    object.currentIndex = 0;
                    $('.current_location').text(object.currentIndex);
                });
                $.each(selfCR.markerHandlerIT, function (_index, object) {
                    object.currentIndex = 0;
                    $('.current_location').text(object.currentIndex);
                });
            }
            show_marker_hanlders(currentTab);
        });
        $('.btn-search-result-nav').on('click', function () {
            let tabType = window.location.pathname.substr(window.location.pathname.lastIndexOf('/') + 1);
            if ($.inArray(tabType, ['transcript', 'description', 'index']) < 0)
                tabType = 'description';
            show_marker_hanlders(tabType);
        });
        if (selfCR.has_loaded == false) {
            try {
                if (typeof selfCR.events_tracker != 'undefined') {
                    selfCR.events_tracker.track_tab_hits(tabType);
                }
            } catch (e) {
                e;
            }
            selfCR.has_loaded = true;
        }
    };

    const show_marker_hanlders = function (tabType) {
        $('.single_term_handler').addClass('d-none');
        $('.single_term_handler').removeClass('open');
        $('.single_term_handler.' + tabType).removeClass('d-none');
        $('.single_term_handler.' + tabType).addClass('open');
    };

    this.show_marker_hanlders = function (tabType) {
        show_marker_hanlders(tabType);

    };

    const initTimeline = function () {
        document_level_binding_element('.timeline-point', 'click', function () {
            $('#index-auto-scroll').prop("checked", false);
            let data = $(this).data();
            $('.timeline-point.dark-orange').addClass('light-orange');
            $('.timeline-point.dark-orange').removeClass('dark-orange');
            $(this).addClass('dark-orange');
            if (!selfCR.indexes.index_visible_pages.includes(parseInt(data.pageNumber, 10))) {
                selfCR.indexes.specific_page_load('timeline', data.pageNumber, false, '#' + data.type + '_timecode_' + data.point);
            } else {
                selfCR.indexes.to_index_transcript_point(data);
            }

        });
    };


    const initCreateTranscription = function () {
        $('#transcription_service_type').change(function () {
            currentVal = $(this).val();
            amount = parseFloat($('#transcript_price_section').data('amount'));
            duration = parseFloat($('#transcript_price_section').data('duration'));
            if (currentVal == 'free') {
                $('#transcript_price_section').text('$0.00');
            } else {
                fee = amount * duration;
                if (fee < 0.50)
                    fee = 0.50;
                $('#transcript_price_section').text('$' + fee.toFixed(2));
            }
        });
    };

    const initCopyLink = function () {
        var clipboard = new Clipboard('.copy-link');
        $('.copy-link').tooltip({
            trigger: 'click',
            placement: 'bottom'
        });

        function setTooltip(btn, message) {
            $(btn).tooltip('show')
                .attr('data-original-title', message)
                .tooltip('show');
        }

        function hideTooltip(btn) {
            setTimeout(function () {
                $(btn).tooltip('hide');
            }, 1000);
        }

        clipboard.on('success', function (e) {
            setTooltip(e.trigger, 'Copied!');
            hideTooltip(e.trigger);
        });

        clipboard.on('error', function (e) {
            setTooltip(e.trigger, 'Failed!');
            hideTooltip(e.trigger);
        });

        $('#public_access_time_period').daterangepicker({
            locale: {format: 'MM-DD-YYYY'}
        }, function (start, end, label) {
            selfCR.setPeriodTimePeriod(start.format('MM-DD-YYYY'), end.format('MM-DD-YYYY'));
        });

    };

    this.setPeriodTimePeriod = function (start, end) {
        let data = {
            action: 'encrypted_info',
            text_to_be_encrypted: start + ' ' + end + ' ' + $('#public_access_time_period').data('resoruceid')
        };
        selfCR.app_helper.classAction($('#public_access_time_period').data('url'), data, 'JSON', 'GET', '', selfCR, true);
    };

    this.encrypted_info = function (response) {
        let new_url = selfCR.app_helper.removeParam('share', $('#public_access_url').text());
        new_url = new_url.replace("?", "");
        let text = new_url + '?share=' + response.encrypted_data;
        $('#public_access_url').text(text);
    };

    this.rss_metadata = function (classname) {

        if (Object.getOwnPropertyNames(selfCR.app_helper).length < 1) {
            selfCR.app_helper = new App();
        }
        var clipboard = new Clipboard('.copy-link');
        init_tinymce_for_element('#' + classname + '_content');
        $("#" + classname + "_add_rss_information").on("change", function () {
            if (this.checked) {
                $(".show_metadata").removeClass("d-none");
            } else {
                $(".show_metadata").addClass("d-none");
                var meta_fields = {
                    "_keywords": "",
                    "_explicit": "false",
                    "_episode_type": "full",
                    "_episode": "",
                    "_season": "",
                    "_content": "",
                };
                Object.keys(meta_fields).forEach(function (key) {
                    $("#" + classname + key).val(meta_fields[key]);
                });
            }
        }).change();
        detailsPageBinding();
    };

    this.loadCollectionwiseResources = function () {
        let loading = true;
        let loading_resources = setInterval(function () {
            let collection_wise_resources = $('.collection_wise_resources').children();
            if (collection_wise_resources.length > 0) {
                collection_wise_resources.each(function (index) {
                    if ($(this).html().trim() == "" && loading) {
                        loading = false;
                        let id = $(this).attr('id');
                        let collection_id = $(this).data('id');
                        let path = $(this).data('path');
                        $.ajax({
                            type: 'GET',
                            url: path,
                            data: {id: collection_id},
                            dataType: 'json',
                            success: function (response) {
                                $('.loader').hide();
                                if (response.partial.indexOf("div") >= 0) {
                                    $('#' + id).html(response.partial);
                                } else {
                                    $('#' + id).remove();
                                }
                                loading = true;
                            },
                            beforeSend: function () {
                                jsloader('#' + id);
                            },
                            error: function (xhr, ajaxOptions, thrownError) {
                                var er = JSON.parse(xhr.responseText)
                                console.log(er)
                            }
                        });
                    }
                    // });
                });
                if (loading)
                    clearInterval(loading_resources);
            }
        }, 500);
    }
}
