/**
 * Resource File Upload Manager
 *
 * @author Furqan Wasi<furqan@weareavp.com, furqan.wasi66@gmail.com>
 *
 * Upload Manager
 *
 * @returns {UploadManager}
 *
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 */

var selfUM;
var files = {
    'fileuploadAll': [],
    'fileuploadTab': []

};

function UploadManager(app_helper) {
    selfUM = this;
    selfUM.app_helper = app_helper;
    selfUM.media_player = null;
    var that = this;

    /**
     *
     * @returns {none}
     */
    this.initialize = function () {
        setTabFocus();
        bindings();
        if ($('.info-btn').length > 0) {
            $('.info-btn').popover({
                html: true,
                trigger: "click",
                placement: "top"
            });
        }
        CheckEmbedType('');
    };

    /**
     *
     * @param data
     * @param uploadErrors
     */
    const error_checker = function (data, uploadErrors) {
        $.each(data.originalFiles, function (index, singel_file) {
            var allowed_types = ['audio/mpeg', 'audio/x-wav', 'audio/ogg', 'audio/wav', 'audio/mp3', 'audio/x-m4a', 'video/mp4', 'video/x-m4v', 'video/ogg', 'video/x-ms-wmv', 'video/webm', 'video/x-flv', 'video/quicktime'];
            if (!allowed_types.includes(singel_file['type'])) {
                uploadErrors.push('Invalid file type, select another file');
                return uploadErrors;
            }

        });
        if (uploadErrors.length > 0) {
            jsMessages('danger', uploadErrors.join("\n"));
            return false;
        }
        return true;

    };

    /**
     * Bind all elemets
     *
     * @returns {undefined}
     */
    const bindings = function () {
        $(function () {
            'use strict';
            $('.fileuploadAll, .fileuploadTab').fileupload({
                url: $('.single-file-upload-form').attr('action'),
                dataType: 'json',
                autoUpload: false,
                sequentialUploads: true,
                singleFileUploads: false,
                done: function (e, data) {
                    files = [];
                    let response = data.result[0];
                    selfUM.app_helper.hide_loader();
                    if (response.error != '') {
                        jsMessages('danger', response.error);
                    } else {
                        jsMessages('success', response.message);
                    }
                    setTimeout(function () {
                        window.location.reload();
                    }, 5000);

                },
                add: function (e, data) {
                    var uploadErrors = [];
                    uploadErrors = error_checker(data, uploadErrors);
                    if (uploadErrors && data.originalFiles[0]['size'] <= 15 * (1024 * 1024 * 1024)) {
                        var div_id = $(this).data('id');
                        var curr_class = 'fileuploadAll';
                        var updateClass = "file_upload_save";
                        if ($(this).attr('class').indexOf("fileuploadTab") >= 0) {
                            curr_class = 'fileuploadTab';
                            updateClass = "file_upload_edit";
                            files[curr_class] = [];
                        }
                        $.each(data.files, function (index, file) {
                            if (div_id == 'filesTab') {
                                $('#' + div_id).text(file.name);
                            } else {
                                $('#' + div_id).append(file.name + '<br/>');
                            }
                            if (files[curr_class].indexOf(file) < 0) {
                                files[curr_class].push(file);
                            }
                        });
                    } else if (data.originalFiles[0]['size'] > 15 * (1024 * 1024 * 1024)) {
                        jsMessages('danger', 'Filesize cannot be more then 2 GB.');
                    }

                    $("." + updateClass).on('click', function () {
                        data.files = files[curr_class];
                        data.submit();
                    });
                },
                progressall: function (e, data) {
                    selfUM.app_helper.show_loader();
                    var progress = parseInt(data.loaded / data.total * 100, 10);

                    $('#' + $(this).data('progress') + ' .progress-bar').css(
                        'width', progress + '%'
                    ).html(progress + '%');
                    if (progress == 100)
                        $('#' + $(this).data('progress') + ' .progress-bar').html('Processing files...');

                }
            }).prop('disabled', !$.support.fileInput)
                .parent().addClass($.support.fileInput ? undefined : 'disabled');

            $(".best_in_place_resoruce_file").best_in_place();

            $('.manage-media-thumbnail').on('click', function () {
                removeImageCustom();
                $('#embeded-information').html('');
                $("#downloadable_duration").addClass("d-none");
                $('.single-file-upload-form-thumbnail').attr('action', $(this).data('url'));
                var file_status = $(this).data('file-status');
                var is_downloadable = $(this).data('file-downloadable');
                var downloadable_till = $(this).data('file-downloadable_till');
                var isCcOn = $(this).data('is_cc_on');
                var download_enabled_for = $(this).data('file-download_enabled_for');
                var $select = $('#collection_resource_file_access').selectize();
                var downloadable = $('#collection_resource_file_is_downloadable')[0].selectize;
                var isCcOnSelect = $('#collection_resource_file_is_cc_on')[0].selectize;
                var selectize = $select[0].selectize;
                $('.resource-file-id').val($(this).data('fileId'));
                $('.resource-file-sort-order').val($(this).data('sort'));
                selectize.setValue(file_status, false);
                downloadable.setValue(is_downloadable.toString(), false);
                isCcOnSelect.setValue(isCcOn.toString(), false);
                loadImageThumbnail(this);
                $('.manage-media-modal').modal();
                intialize_datepicker(is_downloadable, download_enabled_for, downloadable_till);
                changeDownloadable();
                changeEnabledOption();
                CheckEmbedType('.manage-media-modal ');
                $('#other-info-holder').html($('#other-info').html());
                binding_embed_local('.manage-media-modal ');
                saveTabFocus(this);
                var embedType = $(this).data('embeded_type');
                var embedUrl = $(this).data('embeded_url');
                var displayName = $(this).data('display_name');
                let html = '<div class="text-headline jumbotron my-2"><h3>Information</h3>';
                html += '<p><b>File Name:</b> '+displayName+'</p>';
                if(embedType && embedUrl)
                {
                    html += '<p><b>Embeded Type:</b> '
                    +embedType+'</p><p><b>Embeded URL:</b> <br><a target="_blank" href="'
                    +embedUrl+'">'+embedUrl+'</a></p>';
                }
                html += '</div>';
                $('#embeded-information').html(html);
                });
        });

        $(".manage-media-modal-close-button").on("click", function(){
            $('#show-thumbnail-image').empty();
        });

        $('.manage-media-thumbnail').on('click', function () {
            $('.video_embed_player').html('');
        });

        binding_embed_local('');

        $('#closeuploadandcontinue').on('click', function () {
            binding_embed_local('')
        });

        $('.edit_close, .closeuploadandcontinue').click(function () {
            location.reload();
        });
    };

    const loadImageThumbnail = function (obj) {
        let data = {
            action: 'loadImageThumbnail'
        };
        app_helper.classAction($('.manage-media-thumbnail').data('removeUrl'), data, 'html', 'GET', '', that , true);
    };

    this.loadImageThumbnail = function (response) {
        if(typeof response != 'undefined' && response != '' && response){
            $('#show-thumbnail-image').append(response);
        }
    };

    const binding_embed_local = function (class_opt) {
        setTimeout(function () {
            $(class_opt + '.check_embed_button').unbind('click');
            $(class_opt + '.check_embed_button').on('click', function () {
                $(class_opt + '#check_file_embed').remove();
                var pattern = new RegExp('^(https?:\\/\\/)?' + // protocol
                    '((([a-z\\d]([a-z\\d-]*[a-z\\d])*)\\.)+[a-z]{2,}|' + // domain name
                    '((\\d{1,3}\\.){3}\\d{1,3}))' + // OR ip (v4) address
                    '(\\:\\d+)?(\\/[-a-z\\d%_.~+]*)*' + // port and path
                    '(\\?[;&a-z\\d%_.~+=-]*)?' + // query string
                    '(\\#[-a-z\\d_]*)?$', 'i');
                if ($(class_opt + '#collection_resource_embed_code').val() != '' && 0 != $(class_opt + '#collection_resource_embed_code').val().length && pattern.test($(class_opt + '#collection_resource_embed_code').val())) {
                    $(class_opt + '.video_embed_player').html("<video preload=\"metadata\" id=\"player_check\" class=\"float-right\" style=\"width:100% !important;height: 200px !important;\">" +
                        "           <source id='check_file_embed' src='" + $(class_opt + '#collection_resource_embed_code').val() + "'>" +
                        "      </video>");
                    $(class_opt + '#player_check')[0].load();
                    if (selfUM.media_player) {
                        selfUM.media_player.remove();
                    }
                    selfUM.media_player = $(class_opt + '#player_check').mediaelementplayer({
                        success: function (mediaElement, domObject) {
                            mediaElement.addEventListener('loadedmetadata', function () {
                                $('#other-info-holder .media-duration').val(secondsToHuman(mediaElement.duration));
                                $('#other-info-holder .media-duration').next().val(mediaElement.duration);
                            });
                        }
                    });
                } else {
                    $(class_opt + '.video_embed_player').html('');
                }
            });

            setTimeout(function () {
                $(class_opt + '.check_embed_clear').on('click', function () {
                    $(class_opt + '.video_embed_player').html('');
                    $(class_opt + '#collection_resource_embed_code').val('');
                });
            }, 100);
        }, 300);
    };

    const changeDownloadable = function () {
        $('#collection_resource_file_is_downloadable').on('change', function () {
            if ($(this).val().toString() == 'true') {
                $("#downloadable_duration").removeClass("d-none");
                changeEnabledOption();
            } else {
                $("#downloadable_duration").addClass("d-none");
                $('#collection_resource_file_download_enabled_for').val('');
                $('#collection_resource_file_downloadable_till').val('');
            }
        });
    };

    const changeEnabledOption = function () {
        $("#collection_resource_file_download_enabled_for").on('change', function () {
            $("#collection_resource_file_downloadable_till").val('');
            if ($(this).val().toString() == 'date') {
                $("#collection_resource_file_downloadable_till").datepicker();
            } else {
                $("#collection_resource_file_downloadable_till").datepicker("destroy");
            }
        });
    };

    const intialize_datepicker = function (ele, val, enabled_till) {
        if (ele) {
            $("#downloadable_duration").removeClass("d-none");
            $("#collection_resource_file_download_enabled_for")[0].selectize.setValue(val);
            $("#collection_resource_file_downloadable_till").val(enabled_till);
            if (val == 'date') {
                $("#collection_resource_file_downloadable_till").datepicker();
            }
        }
    };

    const CheckEmbedType = function (class_opt) {
        bindingElement(class_opt + '#collection_resource_embed_type', 'change', function () {
            $('.only-avalon').hide();
            $('.player-checking').hide();
            $('#embed_code_text').hide();
            $('.field_embed_code').html($('.field_embed_code_parent_text').html());
            $(class_opt + '#other-info-holder').html("");
            if ($(this).val() == 4) {
                $('.only-avalon').show();
            } else if ($(this).val() == 0) {
                $(class_opt + '#other-info-holder').html($('#other-info').html());
                $('.field_embed_code').html($('.field_embed_code_parent_input').html());
                $('.player-checking').show();
                $('#embed_code_text').hide();
            }

        }, true);
        $('.field_embed_code').html($('.field_embed_code_parent_text').html());
        $(class_opt + '.only-avalon').hide();
        $(class_opt + '#other-info-holder').html("");
        if ($(class_opt + '#collection_resource_embed_type').val() == 4) {
            $(class_opt + '.only-avalon').show();
        } else if ($(class_opt + '#collection_resource_embed_type').val() == 0) {
            $(class_opt + '#other-info-holder').html($('#other-info').html());
            $('.field_embed_code').html($('.field_embed_code_parent_input').html());
        }
    };

    const saveTabFocus = (el) => {
      localStorage.setItem('saved_focus', `.${el.className.split(' ').join('.')}[data-file-id="${el.dataset.fileId}"]`);
    }

    const setTabFocus = () => {
      $(localStorage.getItem('saved_focus')).focus();
      localStorage.removeItem('saved_focus');
    }

    this.handlecallback = function (response, container, requestData) {
        try {
            eval('this.' + requestData.action + '(response,container,requestData)');
        } catch (err) {
            console.log(err);
        }
    };
}
