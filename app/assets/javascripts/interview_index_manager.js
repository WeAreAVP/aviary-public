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
        let searchParams = new URLSearchParams(window.location.search)
        host = $('#media_host').data('host')
        if($('.tokenfield').length > 0){
            $('.tokenfield_keywords').tokenfield({
                delimiter: ';',
                autocomplete: {
                source: $(".tokenfield_keywords").data().items,
                delay: 100
                },
                showAutocompleteOnFocus: false
            });
            $('.tokenfield_subjects').tokenfield({
                delimiter: ';',
                autocomplete: {
                source: $('.tokenfield_subjects').data().items,
                delay: 100
                },
                showAutocompleteOnFocus: false
            });
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
                    $('.player-section').css('visibility','unset');
                });
            }
            else
            {
                let videoJsOptions = {
                    fluid: true,
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
                            }, 2000);
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
                                }, 2000);
                            }, 4000);
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
                            }, 2000);
                        }
                        
                    }
                    $('.player-section').css('visibility','unset');
                });
            
            }
        }
        
        
    };
    const bindEvents = function () {
        let containerRepeatManager = new ContainerRepeatManager();
        containerRepeatManager.makeContainerRepeatable(".add_gps", ".remove_gps", '.container_gps_inner', '.container_gps', '.gps');
        containerRepeatManager.makeContainerRepeatable(".add_hyperlinks", ".remove_hyperlinks", '.container_hyperlinks_inner', '.container_hyperlinks', '.hyperlinks');
        document_level_binding_element('.update_time', 'click', function () {
            updateTime();
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
            let message = 'Are you sure you want to remove this index point?';
            $('#modalPopupBody').html(message);
            $('#modalPopupTitle').html('Delete "' + $(this).data().name + '"');
            $('#modalPopup').modal('show');
        });
        document_level_binding_element('.simple_form', 'change', function () {
            formChange = 1;
        });
        document_level_binding_element('.btn-success', 'click', function () {
            formChange = 0;
        });
        
    };
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
    const updateTime = function () {
        if(host == "SoundCloud")
        {
            widget_soundcloud.getPosition(function (pos) {
                let time = Math.floor(pos * 0.001);
                $('.video_time').val(secondsToHuman(time));
            })
        }
        else
        {
            if($('.no-media').length > 0)
                $('.video_time').val($('.video_input').val());
            else
                $('.video_time').val(secondsToHuman(getTime()));
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
