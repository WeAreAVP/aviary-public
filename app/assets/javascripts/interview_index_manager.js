/**
 * Interviews Indexes Manager
 *
 * @author Raza Saleem <raza@weareavp.com>
 *
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 *
 */
"use strict";

function InterviewIndexManager() {
    let that = this;
    let player_widget;
    let timeDiffInSec = 10;
    let timeSubInSec = 5;
    let startTime = 0;
    let formChange = 0;
    let widget_soundcloud;
    let host = "";
    this.initialize = function () {
        $('[data-toggle="tooltip"]').tooltip();
        bindEvents();
        setIterviewNotes();
        let searchParams = new URLSearchParams(window.location.search)
        host = $('#media_host').data('host')
        if($('.tokenfield').length > 0){
            const keywords_options = {
                minLength: 1,
                delimiter: [';'],
                beautify: true,
            }

            if ($('.tokenfield_keywords').data('path') !== undefined) {
                keywords_options.autocomplete = {
                    source: function( request, response ) {
                        $.ajax({
                            url: $('.tokenfield_keywords').data('path'),
                            dataType: "json",
                            data: {
                                term: request.term,
                                tId: $('.tokenfield_keywords').data('tId'),
                                typeOfList: $('.tokenfield_keywords').data('typeOfList')
                            },
                            success: function( data ) {
                              response( data );
                            }
                        });
                    },
                }
            }

            $('.tokenfield_keywords').tokenfield(keywords_options);

            const subjects_options = {
                minLength: 1,
                delimiter: [';'],
                beautify: true,
            }

            if ($('.tokenfield_subjects').data('path') !== undefined) {
            subjects_options.autocomplete = {
                source: function( request, response ) {
                    $.ajax({
                        url: $('.tokenfield_subjects').data('path'),
                        dataType: "json",
                        data: {
                            term: request.term,
                            tId: $('.tokenfield_subjects').data('tId'),
                            typeOfList: $('.tokenfield_subjects').data('typeOfList')
                        },
                        success: function( data ) {
                          response( data );
                        }
                    });
                },
            }
            }

            $('.tokenfield_subjects').tokenfield(subjects_options);
        }
        if($('.no-media').length > 0)
        {
            $('.music_btn').hide();
            $('.video_input').prop("disabled", false);
            $(".video_input").mask("00:00:00",{
                clearIfNotMatch : true
            });
            $('.interviews_interview_index_time').append('<small class="form-text text-muted mt-1">Timestamp should be in HH:MM:SS format.</small>');
            $( ".video_input" ).change(function() {
                $('.video_time').val($('.video_input').val());
            });
        }
        else{
            if(host == "Kaltura")
            {
                setTimeout(function(){ 
                    $('#item_length').val(kdp.evaluate('{duration}'));
                }, 6000);
                if(searchParams.has('time'))
                {
                    startTime = parseFloat(searchParams.get('time'));
                    setTimeout(function(){ 
                        kdp.sendNotification('doSeek', parseFloat(searchParams.get('time')));
                        $('.video_time').val(secondsToHuman(parseFloat(searchParams.get('time'))));
                        kdp.sendNotification('doPlay');
                    }, 4000);
                }
                else
                {
                    var edit = $('.video_time').val();
                    if(edit !== undefined && edit !== "00:00:00")
                    {
                        let new_time = humanToSeconds(edit);
                        startTime = parseFloat(new_time);
                        setTimeout(function(){ 
                            kdp.sendNotification('doSeek', parseFloat(new_time));
                            $('.video_time').val(secondsToHuman(parseFloat(new_time)));
                            kdp.sendNotification('doPlay');
                        }, 4000);
                    }
                    else{
                        setTimeout(function(){ 
                            kdp.sendNotification('doPlay');
                        }, 4000);
                    }
                }

                setTimeout(function () {
                    kdp.kBind('mediaLoaded', function () {
                        getIndexSegmentsTimeline(kdp.evaluate('{duration}'), host);
                    });
                }, 1000);

                $('.player-section').css('visibility','unset');
            }
            else if(host == "SoundCloud")
            {
                widget_soundcloud = SC.Widget(document.getElementById('soundcloud_widget'));
                widget_soundcloud.bind(SC.Widget.Events.READY, function () {
                    setTimeout(function(){ 
                        widget_soundcloud.getDuration(function (pos) {
                            $('#item_length').val(pos*0.001);
                        })
                    },6000);
                    if(searchParams.has('time'))
                    {
                        startTime = parseFloat(searchParams.get('time')/0.001);
                        setTimeout(function(){ 
                            widget_soundcloud.seekTo(parseFloat(searchParams.get('time')/0.001));
                            $('.video_time').val(secondsToHuman(parseFloat(searchParams.get('time'))));
                            widget_soundcloud.play();
                        }, 3000);
                    }
                    else
                    {
                        var edit = $('.video_time').val();
                        if(edit !== undefined && edit !== "00:00:00")
                        {
                            let new_time = humanToSeconds(edit);
                            startTime = parseFloat(new_time/0.001);
                            setTimeout(function(){ 
                                widget_soundcloud.seekTo(parseFloat(new_time/0.001));
                                $('.video_time').val(secondsToHuman(parseFloat(new_time)));
                                widget_soundcloud.play();
                            }, 3000);
                        }
                        else
                        {
                            setTimeout(function(){
                                widget_soundcloud.play(); 
                            }, 2000);
                        }
                    }

                    $('.player-section').css('visibility', 'unset');

                    widget_soundcloud.getDuration(function (pos) {
                        getIndexSegmentsTimeline(pos * 0.001, host);
                    });

                    $('.player-section').css('visibility','unset');
                });
            }
            else
            {
                let videoJsOptions = {
                    fluid: true,
                    playbackRates: [0.5, 1, 1.5, 2],
                    aspectRatio: '16:9',
                    responsive: true,
                    preload: true,
                    soundcloudClientId: '95f22ed54a5c297b1c41f72d713623ef',
                    techOrder: ['html5', 'youtube', 'vimeo', 'brightcove'],
                    youtube: {autohide: 1},
                    plugins: {
                        airplayButton: {},
                        constantTimeupdate: {
                            interval: 1000,
                            roundFn: Math.round
                        }
                    }
                };
                if ($('#player_section').hasClass('audio-player')){
                    videoJsOptions.aspectRatio = '1:0';
                    videoJsOptions.controlBar = {
                        "fullscreenToggle": false,
                        'pictureInPictureToggle': false
                    };
                }
                player_widget = videojs('player', videoJsOptions, function onPlayerReady() {
                    setTimeout(function(){ 
                        $('#item_length').val(player_widget.duration());
                    },6000);
                    if(searchParams.has('time'))
                    {
                        startTime = parseFloat(searchParams.get('time'));
                        setTimeout(function(){ 
                            player_widget.currentTime(parseFloat(searchParams.get('time')));
                            $('.video_time').val(secondsToHuman(parseFloat(searchParams.get('time'))));
                            setTimeout(function () {
                                let playPromise = undefined;
                                    playPromise = player_widget.play();
                                
                    
                                if (playPromise !== undefined) {
                                    playPromise.then(function () {
                                        player_widget.currentTime(parseFloat(searchParams.get('time')));
                                        player_widget.play();
                                        // Automatic playback started. No need to do anything.
                                    }).catch(function (_error) {
                                        document.addEventListener('click', function () {
                                            player_widget.muted(false);
                                        });
                                        player_widget.muted(true);
                                        setTimeout(function(){  player_widget.play(); }, 1000);
                                        
                                    });
                                }
                            }, 1000);
                        }, 1000);
                    }
                    else
                    {
                        var edit = $('.video_time').val();
                        if(edit !== undefined && edit !== "00:00:00")
                        {
                            let new_time = humanToSeconds(edit);
                            startTime = parseFloat(new_time);
                            setTimeout(function(){ 
                                player_widget.currentTime(parseFloat(new_time));
                                $('.video_time').val(secondsToHuman(parseFloat(new_time)));
                                setTimeout(function () {
                                    let playPromise = undefined;
                                        playPromise = player_widget.play();
                                    
                        
                                    if (playPromise !== undefined) {
                                        playPromise.then(function () {
                                            player_widget.currentTime(parseFloat(new_time));
                                            player_widget.play();
                                            // Automatic playback started. No need to do anything.
                                        }).catch(function (_error) {
                                            document.addEventListener('click', function () {
                                                player_widget.muted(false);
                                            });
                                            player_widget.muted(true);
                                            setTimeout(function(){  player_widget.play(); }, 1000);
                                            
                                        });
                                    }
                                }, 1000);
                            }, 1000);
                        }
                        else
                        {
                            setTimeout(function () {
                                let playPromise = undefined;
                                    playPromise = player_widget.play();
                                
                    
                                if (playPromise !== undefined) {
                                    playPromise.then(function () {
                                        player_widget.play();
                                        // Automatic playback started. No need to do anything.
                                    }).catch(function (_error) {
                                        document.addEventListener('click', function () {
                                            player_widget.muted(false);
                                        });
                                        player_widget.muted(true);
                                        setTimeout(function(){  player_widget.play(); }, 1000);
                                        
                                    });
                                }
                            }, 1000);
                        }
                    }

                    player_widget.on("loadedmetadata", function () {
                        getIndexSegmentsTimeline(player_widget.duration(), host);
                    });
                    
                    $('.player-section').css('visibility','unset');
                });
            }
            setInterval(function () {
                $("#current_time").val(player_widget.currentTime());
            }, 1000);
        }
    };

    const getIndexSegmentsTimeline = function (total_duration, host) {
        $.ajax({
            url: $('#index-segments-timeline').data('url'),
            data: {
                total_duration: total_duration,
                active_point_id: $('#index-segments-timeline').data('activePointId'),
            },
            success: function( response ) {
                $('#index-segments-timeline').append(response);

                if ($('#media-index-timeline-pointer')[0]) {
                    if (host === 'Kaltura') {
                        kdp.kBind('playerUpdatePlayhead', function (currentTime) {
                                let progressPercent = currentTime / total_duration;
                                $('#media-index-timeline-pointer').css('left', `${progressPercent * 100}%`);
                        });
                    }  else if (host === 'SoundCloud') {
                        widget_soundcloud.bind(SC.Widget.Events.PLAY_PROGRESS, function () {
                            widget_soundcloud.getPosition(function (pos) {
                                let progressPercent = pos * 0.001 / total_duration;
                                $('#media-index-timeline-pointer').css('left', `${progressPercent * 100}%`);
                            })
                        });
                    } else {
                        player_widget.on('constant-timeupdate', updateIndexPointer);

                        let progressPercent = player_widget.cache_.currentTime / total_duration;
                        $('#media-index-timeline-pointer').css('left', `${progressPercent * 100}%`);
                    }
                }
            }
        });
    }

    const bindEvents = function () {
        let containerRepeatManager = new ContainerRepeatManager();
        containerRepeatManager.makeContainerRepeatable(".add_gps", ".remove_gps", '.container_gps_inner', '.container_gps', '.gps');
        containerRepeatManager.makeContainerRepeatable(".add_hyperlinks", ".remove_hyperlinks", '.container_hyperlinks_inner', '.container_hyperlinks', '.hyperlinks');
        document_level_binding_element('.update_time', 'click', function () {
            updateTime(this);
        });
        document_level_binding_element('.update_backward', 'click', function () {
            updateBackward();
        });
        document_level_binding_element('.update_play', 'click', function () {
            updatePlay();
        });
        document_level_binding_element('.update_pause', 'click', function () {
            updatePause();
        });
        document_level_binding_element('.update_forward', 'click', function () {
            updateForward();
        });
        document_level_binding_element('.add_tag', 'click', function () {
            updateTimeInURL();
        });
        
        document_level_binding_element('.update_step_backward', 'click', function () {
            updateStepBackward();
        });
        document_level_binding_element('.add_gps', 'click', function () {
            $('select').not(':has(option:selected)').val(17)
        });
        document_level_binding_element('.index_status_select', 'change', function () {
            let formData = {
                'index_status': $(this).val()
            }
            $.ajax({
                url: $(this).data().url,
                data: formData,
                type: 'POST',
                dataType: 'json',
                success: function (response) {
                    jsMessages('success', 'Index point status updated successfully.');
                },
            });
        });

        document_level_binding_element('.delete_index', 'click', function () {
            $('#modalPopupFooterYes').attr('href', $(this).data().url);
            let message = 'Are you sure you want to delete this index segment?';
            $('#modalPopupBody').html(message);
            $('#modalPopupTitle').html('Delete "' + $(this).data().name + '"');
            $('#modalPopup').modal('show');
        });

        document_level_binding_element('.simple_form', 'change, keyup', function () {
            formChange = 1;
        });

        document_level_binding_element('.simple_form', 'submit', function (e) {
            e.preventDefault();

            if (!$('.timestamp-errors').length) {
                formChange = 0;

                this.submit();
            } else {
                setTimeout(() => {
                    $('input[type="submit"]').prop('disabled', false)
                }, 100);
                jsMessages('danger', 'Please ensure the timestamps are not out of bound');
            }
        });

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
        

        document_level_binding_element('.save_and_new', 'click', function () {
            if ($('timestamp-errors').length) {
                var url = $('.interview_index_manager').attr("action")
                if(!url.includes("new=1"))
                {
                    $('.interview_index_manager').attr("action", url+"?new=1");
                }
            }
        });

        document_level_binding_element('#toggle_all', 'click', function () {
            if ($(this).text().trim() === 'Expand All') {
                $('#accordionIndex div[id^="collapse_"]').addClass('show');
                $('#accordionIndex div[id^="collapse_"]').removeClass('collapse');
                $('.btn-collapse').removeClass('collapsed');
                $('.btn-collapse').attr('aria-expanded', true);
                $(this).removeClass('btn-down');
                $(this).addClass('btn-up');
                $(this).text('Collapse All');
            } else {
                $('#accordionIndex div[id^="collapse_"]').removeClass('show');
                $('#accordionIndex div[id^="collapse_"]').addClass('collapse');
                $('.btn-collapse').addClass('collapsed');
                $('.btn-collapse').attr('aria-expanded', false);
                $(this).removeClass('btn-up');
                $(this).addClass('btn-down');
                $(this).text('Expand All');
            }
        });

        document_level_binding_element('.index-segment', 'click', function () {
            let segmentId = $(this).data('target');

            let segmentButton = $(`.btn-collapse[data-target='#${segmentId}']`);
            if (segmentButton.attr('aria-expanded') === 'false') {
                segmentButton.click();
                $(`.segment-duration.play-timecode.${segmentId}`).click();
            } else {
                $('.frontdrop').removeClass('highlight');
            }

            // Highlight the active index segment on timeline
            $('.index-segment').removeClass('active');
            $(this).addClass('active');

            // Highlight the corresponding index segment
            $('.card-header').removeClass('highlight');
            $(`#heading_${segmentId.replace('collapse_', '')}`).addClass('highlight');

            // Scroll the corresponding index segment into view
            $(`.card.${segmentId}`)[0].scrollIntoView({ behavior: "smooth", block: "nearest", inline: "nearest" });
        });

        document_level_binding_element('.btn-collapse', 'click', function () {
            // Highlight the active index segment on timeline
            $('.index-segment').removeClass('active');
            $('.card-header').removeClass('highlight');
            if ($(this).attr('aria-expanded') === 'true') {
                $(`.index-segment[data-target="${$(this).attr('aria-controls')}"]`).addClass('active');
                $(`.segment-duration.play-timecode.${$(this).attr('aria-controls')}`).click();
            }
        });

        document_level_binding_element('.segment-title', 'click', function (event) {
            event.stopPropagation();
            hideAllSegmentTitleInputs();

            $(this).find('.title').addClass('d-none');
            $(this).find('.edit_title').removeClass('d-none');
        });

        $(window).click('click', hideAllSegmentTitleInputs);

        document_level_binding_element('.save_index_title', 'click', function (event) {
            event.preventDefault();

            const fileIndexPointId = $(this).data('fileIndexPointId');
            if ($(`#file_index_point_title_${fileIndexPointId}`).text() === $(`#edit_file_index_point_title_${fileIndexPointId}`).val())
                return;

            $.ajax({
                url: $(`#save_file_index_point_title_form_${fileIndexPointId}`)[0].action,
                data: $(`#save_file_index_point_title_form_${fileIndexPointId}`).serialize(),
                type: 'POST',
                success: function (response) {
                    jsMessages(response.status, response.message);
                    $(`#file_index_point_title_${fileIndexPointId}`).text(
                        $(`#edit_file_index_point_title_${fileIndexPointId}`).val()
                    );
                    hideAllSegmentTitleInputs();
                },
                error: function (error) {
                    jsMessages('danger', error);
                }
            });
        });

        document_level_binding_element('#index_title_heading', 'click', function (event) {
            event.stopPropagation();

            $(this).addClass('d-none');
            $('#save_file_index_title_form').removeClass('d-none');
            $('#save_file_index_title_form').addClass('d-flex');
        });

        document_level_binding_element('.cancel_file_index_title', 'click', hideAllSegmentTitleInputs);

        document_level_binding_element('.save_file_index_title', 'click', function (event) {
            event.preventDefault();

            if ($('#index_title_heading').text().trim() === $('#edit_file_index_title').val())
                return;

            $.ajax({
                url: $('#save_file_index_title_form')[0].action,
                data: $('#save_file_index_title_form').serialize(),
                type: 'POST',
                success: function (response) {
                    jsMessages(response.status, response.message);
                    $('#index_title_heading').text(
                        $('#edit_file_index_title').val()
                    );
                    hideAllSegmentTitleInputs();
                },
                error: function (error) {
                    jsMessages('danger', error);
                }
            });
        });

        setTimeout(() => {
            document_level_binding_element('.edit-time', 'click', function (e) {
                let timecode = prompt('Change timecode (HH:MM:SS)', $($(this).data('timeTarget')).val());

                if (timecode.match(/^\d{2}:[0-5]\d:[0-5]\d$/)) {
                    timeArray = timecode.split(':');
                    switch (host) {
                        case 'Kaltura':
                            videoDuration = kdp.evaluate('{duration}');
                            break;

                        case 'SoundCloud':
                            videoDuration = widget_soundcloud.getDuration();
                            break;

                        default:
                            videoDuration = player_widget.duration();
                            break;
                    }

                    $(`span#${$(this).data('timeTarget').replace('.', '')}-error`).remove();
                    const timeInSeconds = (parseInt(timeArray[0], 10) * 3600) + (parseInt(timeArray[1], 10) * 60) + parseInt(timeArray[2], 10);
                    if (timeInSeconds > videoDuration) {
                        $(`<span id="${$(this).data('timeTarget').replace('.', '')}-error" class="timestamp-errors form_error">Can't be out of bound</span>`).insertAfter(
                            $(`input${$(this).data('timeTarget')}.form-control`)
                        );
                    }

                    $($(this).data('timeTarget')).val(timecode);
                }
            });
        }, 1500);
    };

    function hideAllSegmentTitleInputs() {
        formChange = 0;
        if ($('.segment-title .title')[0]) {
            $('.segment-title .title').removeClass('d-none');
            $('.segment-title .edit_title').addClass('d-none');
        }

        if ($('#index_title_heading')[0]) {
            $('#index_title_heading').removeClass('d-none');
            $('#save_file_index_title_form').addClass('d-none');
            $('#save_file_index_title_form').removeClass('d-flex');
        }
    }  

    function unloadPage(){ 
        if(formChange == 1){
            return "Are you sure you want to leave with unsaved changes?";
        }
    }
    window.onbeforeunload = unloadPage;
    const updatePause = function ()
    {
        if(host == "Kaltura")
        {
            kdp.sendNotification('doPause');
        }
        else if(host == "SoundCloud")
        {
            widget_soundcloud.pause();
        }
        else
        {
            player_widget.pause();
        }
    }
    const updatePlay = function ()
    {
        if(host == "Kaltura")
        {
            kdp.sendNotification('doPlay');
        }
        else if(host == "SoundCloud")
        {
            widget_soundcloud.play();
        }
        else
        {
            player_widget.play();
        }
    }
    const updateForward = function ()
    {
        if(host == "Kaltura")
        {
            kdp.sendNotification('doSeek',  kdp.evaluate('{video.player.currentTime}') + timeDiffInSec);
        }
        else if(host == "SoundCloud")
        {
            widget_soundcloud.getPosition(function (pos) {
                widget_soundcloud.seekTo(pos + (timeDiffInSec/0.001));
            })
        }
        else
        {
            player_widget.currentTime(player_widget.currentTime() + timeDiffInSec);
        }
    }
    const updateBackward = function ()
    {
        if(host == "Kaltura")
        {
            kdp.sendNotification('doSeek',  kdp.evaluate('{video.player.currentTime}') - timeDiffInSec);
        }
        else if(host == "SoundCloud")
        {
            widget_soundcloud.getPosition(function (pos) {
                widget_soundcloud.seekTo(pos - (timeDiffInSec/0.001));
            })
        }
        else
        {
            player_widget.currentTime(player_widget.currentTime() - timeDiffInSec);
        }
    }
    const updateStepBackward = function ()
    {
        let time = humanToSeconds($('#file_index_point_start_time').val())
        if(host == "Kaltura")
        {
            kdp.sendNotification('doSeek',  time);
        }
        else if(host == "SoundCloud")
        {
            widget_soundcloud.seekTo(time/0.001);
        }
        else
        {
            player_widget.currentTime(time);
        }
    }
    const getTime = function ()
    {
        if(host == "Kaltura")
        {
            return kdp.evaluate('{video.player.currentTime}')
        }    
        else
        {
            return player_widget.currentTime();  
        }
    }
    const updateTime = function (button) {
        if(host == "SoundCloud")
        {
            widget_soundcloud.getPosition(function (pos) {
                let time = Math.floor(pos * 0.001);
                $('.video_time').val(secondsToHuman(time));
            })
        }
        else
        {
            let selector = $(button).data('time-target') || '.video_time';
            if ($('.no-media').length > 0)
                $(selector).val($('.video_input').val());
            else
                $(selector).val(secondsToHuman(getTime()));
        }
    };

    const updateTimeInURL = function () {
        if(host == "SoundCloud")
        {
            widget_soundcloud.getPosition(function (pos) {
                let time = Math.floor(pos * 0.001);
                time = time - timeSubInSec;
                if (time < 0) time = 0;
                window.location = $('.add_tag').data().url+'?time='+time;
            })
        }
        else
        {
            if($('.no-media').length > 0)
                window.location = $('.add_tag').data().url;
            else
            {
                let time = getTime();
                time = time - timeSubInSec;
                if (time < 0) time = 0;
                window.location = $('.add_tag').data().url+'?time='+time;
            }
                
        }
    };
    this.handlecallback = function (response, container, requestData) {
        try {
            eval('this.' + requestData.action + '(response,container,requestData)');
        } catch (err) {
            console.log(err);
        }
    };
}
