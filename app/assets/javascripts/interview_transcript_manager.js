/**
 * Interview Transcript Manager
 *
 * @author Furqan Wasi <furqan@weareavp.com>
 *
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 *
 */
 "use strict";

 function InterviewTranscriptManager() {
     let that = this;
     let player_widget;
     let timeDiffInSec = 60;
     let startTime = 0;
     let timecode = null;
     let widget_soundcloud;
     let currentPoint = 0;
     let host = "";
     let appHelper = new App();
     let audioBegin = null;
     let audioEnd = null;
 
     this.initialize = function () {
         timeDiffInSec = parseFloat($('#interviews_interview_timecode_intervals').val()) * 60;
         bindEvents();
         let searchParams = new URLSearchParams(window.location.search);
         host = $('#media_host').data('host');
         if ($('.tokenfield').length > 0) {
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
         // ######
         if ($('.no-media').length > 0) {
             $('.music_btn').hide();
             $('.video_input').prop("disabled", false);
             $(".video_input").mask("00:00:00", {
                 clearIfNotMatch: true
             });
             $('.interviews_interview_index_time').append('<small class="form-text text-muted mt-1">Timestamp should be in HH:MM:SS format.</small>');
             $(".video_input").change(function () {
                 $('.video_time').val($('.video_input').val());
             });
         } else {
             if (host == "Kaltura") {
                 setTimeout(function () {
                     $('#item_length').val(kdp.evaluate('{duration}'));
                 }, 6000);
 
                 $('.player-section').css('visibility', 'unset');
             } else if (host == "SoundCloud") {
                 widget_soundcloud = SC.Widget(document.getElementById('soundcloud_widget'));
                 widget_soundcloud.bind(SC.Widget.Events.READY, function () {
                     setTimeout(function () {
                         widget_soundcloud.getDuration(function (pos) {
                             $('#item_length').val(pos * 0.001);
                         })
                     }, 6000);
                     $('.player-section').css('visibility', 'unset');
                 });
             } else {
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
                 if ($('#player_section').hasClass('audio-player')) {
                     videoJsOptions.aspectRatio = '1:0';
                     videoJsOptions.controlBar = {
                         "fullscreenToggle": false,
                         'pictureInPictureToggle': false
                     };
                 }
                 player_widget = videojs('player', videoJsOptions, function onPlayerReady() {
                     setTimeout(function () {
                         $('#item_length').val(player_widget.duration());
                     }, 6000);
                     player_widget.on('constant-timeupdate', function (e) {
                         updateTime();
 
                         let playerTime = parseInt(this.currentTime(), 10);
                         let playerState = false;
                         var minVal = getMinVal();
                         let rangeVal = parseInt($('.video_player_delay').val(), 10);
                         let hours = Math.floor(playerTime / 3600);
                         let minutes = Math.floor((playerTime - (hours * 3600)) / 60);
                         let seconds = playerTime - ((hours * 3600) + (minutes * 60));
 
                         hours = pad(hours, 2, '0');
                         minutes = pad(minutes, 2, '0');
                         seconds = pad(seconds, 2, '0');
 
                         if (isNaN(hours))
                             hours = '00';
                         if (isNaN(minutes))
                             minutes = '00';
                         if (isNaN(seconds))
                             seconds = '00';
                         if (isNaN(minVal))
                             minVal = 0;
                         if (isNaN(rangeVal))
                             rangeVal = 10;
                         if (playerState == false) {
 
 
                             if (minVal == 0) {
                                 if (playerTime == 0) {
                                     that.audioBegin.pause();
                                     that.audioBegin.play();
                                 }
                                 
                                 if (playerTime == rangeVal / 2) {
                                     that.audioEnd.pause();
                                     that.audioEnd.play();
                                 }
                                 if (playerTime >= rangeVal) {
                                     player_widget.currentTime(0);
                                 }
 
                             } else {
 
 
                                 if (playerTime < ((minVal * 60) - rangeVal) || playerTime > ((minVal * 60) + rangeVal)) {
                                     player_widget.currentTime((minVal * 60) - rangeVal);
                                     that.audioBegin.pause();
                                 }
 
                                 if (playerTime == ((minVal * 60) - rangeVal)) {
                                     that.audioBegin.pause();
                                     that.audioBegin.play();
                                 }
                                 
                                 if (playerTime == (minVal * 60)) {
                                     that.audioEnd.pause();
                                     that.audioEnd.play();
                                 }
 
                                 if (playerTime >= ((minVal * 60) + rangeVal)) {
                                     player_widget.currentTime((minVal * 60) - rangeVal);
                                 }
                             }
                         }
                     });
                     $('.player-section').css('visibility', 'unset');
                 });
 
             }
         }
     };
 
     const syncUpdate = function () {
         if (typeof $(".single_word_transcript.cursor-pointer") != 'undefined') {
             $(".single_word_transcript.cursor-pointer").contents().unwrap();
         }
 
         if (typeof $(".single_point_transcript") != 'undefined') {
             $('.single_point_transcript').each(function(){
                 let text = $(this).text();
                 text = text.replaceAll('\n' , '');
                 $(this).text(text);
             });
         }
 
         if (typeof $(".single_point_transcript") != 'undefined') {
             $('.transcript_point_code').each(function() {
                 let text = $(this).text();
                 if ($(this).next().length > 0 ){
                     let tagetElement = $(this).next();
                     text = text + $(tagetElement).text()
                     text = text.replaceAll("\n" , '');
                     $(tagetElement).text(text);
                 } else if($(this).prev().length > 0 ) {
                     let tagetElement = $(this).prev();
                     $(tagetElement).text($(tagetElement).text() + text);
                 }
                 $(this).remove();
                 return false; 
             });
         }
 
         if (typeof $(".single_point_transcript") != 'undefined') {
             $('.single_point_transcript').contents().unwrap();
             $('#main_transcript_textarea').text($('.main_transcript_for_edit').text().replace(/  +/g, ' '));
         }  
     };
 
     this.kalturaManager = function (kdp) {
               
         var playerTime = Math.floor(kdp.evaluate('{video.player.currentTime}'));
         let playerState = false;
         var minVal = getMinVal();
         let rangeVal = parseInt($('.video_player_delay').val(), 10);
         let hours = Math.floor(playerTime / 3600);
         let minutes = Math.floor((playerTime - (hours * 3600)) / 60);
         let seconds = playerTime - ((hours * 3600) + (minutes * 60));
 
         hours = pad(hours, 2, '0');
         minutes = pad(minutes, 2, '0');
         seconds = pad(seconds, 2, '0');
 
         if (isNaN(hours))
             hours = '00';
         if (isNaN(minutes))
             minutes = '00';
         if (isNaN(seconds))
             seconds = '00';
         if (isNaN(minVal))
             minVal = 0;
         if (isNaN(rangeVal))
             rangeVal = 10;
         if (playerState == false) {
           if (minVal == 0) {
               if (playerTime == 0) {
                   that.audioBegin.pause();
                   that.audioBegin.play();
               }
               if (playerTime == rangeVal / 2) {
                   that.audioEnd.pause();
                   that.audioEnd.play();
               }
               if (playerTime >= rangeVal) {
                   kdp.sendNotification('doSeek', 0);
               }
           } else {
               if (playerTime < ((minVal * 60) - rangeVal) || playerTime > ((minVal * 60) + rangeVal)) {
                   kdp.sendNotification('doSeek', ((minVal * 60) - rangeVal));
                   that.audioBegin.pause();
               }
               if (playerTime == ((minVal * 60) - rangeVal)) {
                   that.audioBegin.pause();
                   that.audioBegin.play();
               }
               if (playerTime == (minVal * 60)) {
                   that.audioEnd.pause();
                   that.audioEnd.play();
               }
               if (playerTime >= ((minVal * 60) + rangeVal)) {
                   kdp.sendNotification('doSeek', ((minVal * 60) - rangeVal));
               }
           }
         }
         $('.current_player_time').val(hours + ':' + minutes + ':' + seconds);
     };
 
     const getMinVal = function () {
         var mtime = $('.current_transcript_point').val();
         var mSecs = 0;
         var mhours = 0;
         if (mtime.indexOf(':') !== -1) {
             var parts = mtime.split(":");
             var minVal = parseInt(parts[1], 10);
             mSecs = parseInt(parts[2], 10);
             mhours = parseInt(parts[0], 10);
         } else {
             var minVal = parseInt(mtime, 10);
         }
         
         if (mhours > 0) {
             minVal = minVal + (mhours * 60) ;
         }
 
         if (mSecs == 30) {
             minVal = minVal + 0.5;
         }
 
         return minVal;
     };
 
     
     const bindEvents = function () {
 
         document_level_binding_element('#interviews_interview_timecode_intervals', 'change', function () {
             if ($(this).val() != interviews_transcript_manager.timecode) {
                 $('#general_modal_close_cust_success').attr('href', $('#timecode_intervals_url').data('url') + '?timecode=' + $(this).val());
                 $('#general_modal_close_cust_success').removeClass('d-none');
                 appHelper.show_modal_message('Confirmation', '<strong>Changing the sync interval will delete all previously added sync points. Are you sure you want to continue?</strong><br/><br/>', 'danger', null);
             }
         });
 
         document_level_binding_element('.update_time', 'click', function () {
             updateTime();
         });
 
         document_level_binding_element('.update_backward', 'click', function () {
             updateBackward();
         });
 
         document_level_binding_element('.update_pause', 'click', function () {
             updatePause();
         });
 
         document_level_binding_element('.update_forward', 'click', function () {
             updateForward();
         });
 
         document_level_binding_element('.transcript_point_code', 'dblclick', function () {
             $(this).remove();
             $('#main_transcript_textarea').text($('.main_transcript_for_edit').html());
         });
 
         document_level_binding_element('#save_transcript_information', 'click', function (e) {
             appHelper.show_loader();   
              e.preventDefault();
              syncUpdate();
              setTimeout(function(){
                 $('form.interview_manager').submit();
              }, 1000);
         });
 
         document_level_binding_element('.single_word_transcript', 'click', function () {
 
             let currentPoint = parseFloat($('.player_state_transcript').val());
             if (currentPoint > 0){
                 $('.transcript_point_code_' + currentPoint).remove();
                 $(this).after(' <span class="transcript_point_code text-dark transcript_point_code_' + currentPoint + '" data-time="' + currentPoint + '">[' + secondsToHuman(currentPoint) + ']</span> ');
             }
             $(this).addClass('bg-success');
             updateForward();
         });
     };
 
     const updatePause = function () {
         if (host == "Kaltura") {
             kdp.sendNotification('doPause');
         } else if (host == "SoundCloud") {
             widget_soundcloud.pause();
         } else {
             player_widget.pause();
         }
     };
 
     const updateForward = function () {
         let delay = parseFloat($('.video_player_delay').val());
         $('.player_state_transcript').val(parseFloat($('.player_state_transcript').val()) + timeDiffInSec);
         $('.current_transcript_point').val(secondsToHuman(parseFloat($('.player_state_transcript').val())));
         let addTime = parseFloat($('.player_state_transcript').val()) - delay;
     
         if (host == "Kaltura") {
             kdp.sendNotification('doSeek', addTime);
         } else if (host == "SoundCloud") {
             widget_soundcloud.getPosition(function (pos) {
                 widget_soundcloud.seekTo((addTime / 0.001));
             });
         } else {
             player_widget.currentTime(addTime);
         }
     };
 
     const updateBackward = function () {
         if (parseFloat($('.player_state_transcript').val()) <= 0) {
             return false;
         }
         let delay = parseFloat($('.video_player_delay').val());
         $('.player_state_transcript').val(parseFloat($('.player_state_transcript').val()) - timeDiffInSec);
         $('.current_transcript_point').val(secondsToHuman(parseFloat($('.player_state_transcript').val())));
         let addTime = parseFloat($('.player_state_transcript').val()) - delay;
 
         if (host == "Kaltura") {
             kdp.sendNotification('doSeek', addTime);
         } else if (host == "SoundCloud") {
             widget_soundcloud.getPosition(function (pos) {
                 widget_soundcloud.seekTo((addTime / 0.001));
             });
         } else {
             player_widget.currentTime(addTime);
         }
     };
 
     const getTime = function () {
         if (host == "Kaltura") {
             return kdp.evaluate('{video.player.currentTime}')
         } else {
             return player_widget.currentTime();
         }
     };
 
     const updateTime = function () {
         if (host == "SoundCloud") {
             widget_soundcloud.getPosition(function (pos) {
                 let time = Math.floor(pos * 0.001);
                 $('.current_player_time').val(secondsToHuman(time));
             })
         } else {
             if ($('.no-media').length > 0)
                 $('.current_player_time').val($('.video_input').val());
             else
                 $('.current_player_time').val(secondsToHuman(getTime()));
         }
     };
 };
 