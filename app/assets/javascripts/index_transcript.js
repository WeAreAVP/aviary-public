/**
 * IndexTranscript management
 *
 * @author Nouman Tayyab<nouman@weareavp.com>
 *
 */


function IndexTranscript() {

    var data;
    var uploadUrl;
    var cuePointType;

    this.initialize = function (type, selected_val) {
        cuePointType = type;
        uploadUrl = $('#new_file_' + cuePointType).attr('action');
        activeFileUploading();
        activateSortable();
        updateOrder();
        activatePoints();
        activatePlayTimecode();
        activateDeletePopup();
        activateUpdatePopup();
        editTranscript();
        finishTranscriptEdit();
        $('#selected_' + cuePointType).val($('#file_' + cuePointType + '_select').val());
        var file_select = $('#file_' + cuePointType + '_select').selectize();
        if ($('#file_' + cuePointType + '_select').length > 0) {
            var file_selectize = file_select[0].selectize;
            if (selected_val > 0) {
                file_selectize.setValue(selected_val);
            }
            activate_export($('#file_' + cuePointType + '_select').val());
            for (cnt in file_selectize.options) {
                let data = file_selectize.options[cnt];
                let value = data['value'];
                if ($('.single_' + cuePointType + '_count_' + value).length > 0) {
                    let count = $('.single_' + cuePointType + '_count_' + value).data('count');
                    let text = data['text'];
                    if (count > 0) {
                        file_selectize.updateOption(value, {
                            text: '<span class="badge badge-pill badge-danger">' + count + '</span> ' + text,
                            value: value
                        });
                    }
                }

            }

        }
    };

    const capitalize = function (s) {
        if (typeof s !== 'string') return '';
        return s.charAt(0).toUpperCase() + s.slice(1);
    };
    let activateUpdatePopup = function () {
        $(".text-danger").html("");
        $('#' + cuePointType + '_update_btn').click(function () {
            current = $('#file_' + cuePointType + '_select');
            $('#new_file_' + cuePointType).attr('action', uploadUrl + '/' + current.val());
            $('#' + cuePointType + '_upload_title').html('Update "' + current.text() + '" ' + capitalize(cuePointType));
            $('#file_' + cuePointType + '_title').val(current.text());
            $('#file_' + cuePointType + '_language')[0].selectize.setValue($('.file_' + cuePointType + '_' + current.val()).data().language);
            $('#file_' + cuePointType + '_is_public')[0].selectize.setValue($('.file_' + cuePointType + '_' + current.val()).data().public.toString());
            $('.upload_' + cuePointType + '_btn').html('Update ' + capitalize(cuePointType));
            $('.upload_' + cuePointType + '_btn').unbind("click").bind("click", function () {

                $(this).prop("disabled", true);
                $.ajax({
                    url: $('#new_file_' + cuePointType).attr('action'),
                    data: $('#new_file_' + cuePointType).serialize(),
                    type: 'POST',
                    dataType: 'json',
                    success: function (response) {
                        checkErrors(response[0]);
                    },
                });
                $(this).html("Processing... ");

            });
        });
        $('#' + cuePointType + '_upload').on('hidden.bs.modal', function () {
            $('#new_file_' + cuePointType).attr('action', uploadUrl);
            $('#' + cuePointType + '_upload_title').html(capitalize(cuePointType) + ' Upload');
            $('#file_' + cuePointType + '_title').val('');
            $('#file_' + cuePointType + '_language')[0].selectize.setValue('en');
            $('#file_' + cuePointType + '_is_public')[0].selectize.setValue('false');
            $('.upload_' + cuePointType + '_btn').html('Upload ' + capitalize(cuePointType));
            $('.upload_' + cuePointType + '_btn').unbind("click");
        });
    };
    let activateDeletePopup = function () {
        $('#delete_' + cuePointType).click(function () {
            $('#modalPopupTitle').html('Delete ' + capitalize(cuePointType));
            currentInfo = $('#file_' + cuePointType + '_select');
            $('#modalPopupBody').html('Are you sure you want to delete this ' + capitalize(cuePointType) + ' information ("' + currentInfo.text() + '") for this file? This operation cannot be undone.');
            $('#modalPopupFooterYes').attr('href', $(this).data().url + currentInfo.val());
            $('#modalPopup').modal('show');
        });
    };
    let activatePlayTimecode = function () {
        $('.play-timecode').click(function () {
            let currentTime = $(this).data().timecode;
            if ($('#avalon_widget').length > 0) {
                player_widget('set_offset', {'offset': currentTime});
                player_widget('play');
            } else {
                player.setCurrentTime(currentTime);
                player.play();
            }
        });
    };
    let activatePoints = function () {
        let selected_element = '.file_' + cuePointType + '_' + $('#file_' + cuePointType + '_select').val();
        $(selected_element).toggleClass('d-none');
        $('.' + cuePointType + '_' + $('#file_' + cuePointType + '_select').val()).toggleClass('d-none');
        $('.file_' + cuePointType + '_' + $('#file_' + cuePointType + '_select').val()).toggleClass('selected_' + cuePointType + 'file');
        $('#file_' + cuePointType + '_select').change(function () {
            $('.file_' + cuePointType).addClass('d-none');
            $('.' + cuePointType + '_timeline').addClass('d-none');
            $('.file_' + cuePointType + '_' + $(this).val()).toggleClass('d-none');
            $('.' + cuePointType + '_' + $(this).val()).toggleClass('d-none');
            $('.file_' + cuePointType).removeClass('selected_' + cuePointType + 'file');
            $('.file_' + cuePointType + '_' + $('#file_' + cuePointType + '_select').val()).addClass('selected_' + cuePointType + 'file');
            $('.' + cuePointType + '_point_container').mCustomScrollbar("scrollTo", 0);
            $('#selected_' + cuePointType).val($('#file_' + cuePointType + '_select').val());
            collectionResource.init_scoll(cuePointType, collectionResource.currentTime, true);
            if (typeof collectionResource.events_tracker != 'undefined' && collectionResource.events_tracker.length > 0)
                collectionResource.events_tracker.track_tab_hits(cuePointType, true);
            activate_export($('#file_' + cuePointType + '_select').val());

        });

        $('[data-toggle="tooltip"]').tooltip();
    };

    let activate_export = function (currentId) {
        if (cuePointType == 'transcript') {
            let selected_element = '.file_' + cuePointType + '_' + currentId;
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
        }


    };
    let activateSortable = function () {
        $('#sortable_' + cuePointType).sortable({
            handle: '.handle',
            activate: function (event, ui) {
                data = $(this).sortable('toArray');
            },
            update: function (event, ui) {
                data = $(this).sortable('toArray');
            }
        }).disableSelection();
        data = $('#sortable_' + cuePointType).sortable('toArray');
    };
    let updateOrder = function () {
        $('.sort_' + cuePointType + '_btn').unbind('click').bind('click', function () {
            let cc = [];
            if (cuePointType == 'transcript') {
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
        $('#file_' + cuePointType + '_associated_file').fileupload({
            formData: $("#new_file_" + cuePointType).serializeArray(),
            autoUpload: false,
            submit: function (e, data) {
                data.formData = $("#new_file_" + cuePointType).serializeArray();
                return true;
            },
            add: function (e, data) {
                $.each(data.files, function (index, file) {
                    $("#file_name_" + cuePointType).html(file.name + "<br/>");
                });
                var fileExtension = ['text/vtt', 'text/webvtt', 'vtt', 'webvtt'];
                if (cuePointType == 'transcript') {
                    if ($.inArray($('#file_name_transcript').text().split('.').pop().toLowerCase(), fileExtension) == -1) {
                        $('.is_caption_section').addClass('d-none');
                        $('.remove_title_section').addClass('d-none');
                    } else {
                        $('.is_caption_section').removeClass('d-none');
                        $('.remove_title_section').removeClass('d-none');
                    }
                }
                $('.upload_' + cuePointType + '_btn').unbind("click").bind("click", function () {
                    $(this).prop("disabled", true);
                    data.submit();
                    $(this).html("Processing...");
                });
            },
            progressall: function (e, data) {
                var progress = parseInt(data.loaded / data.total * 100, 10);
                $('#progress' + cuePointType + ' .progress-bar').css(
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
            $('.upload_' + cuePointType + '_btn').html("Upload " + capitalize(cuePointType)).prop("disabled", false);
            for (cnt in result.errors) {
                $('.' + cnt).html(result.errors[cnt]);
            }
        } else {
            $('.upload_' + cuePointType + '_btn').hide();
            $('#' + cuePointType + '_upload_success').html(capitalize(cuePointType) + " file uploaded successfully.");
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
                setTimeout('window.location.reload();',2000);
            });
        }

    };
    const finishTranscriptEdit = function () {
        if ($('.finish_editing').length > 0) {
            var interval = setInterval(function () {
                localKey = localStorage.getItem('transcript_finish');
                if (localKey == 'true') {
                    localStorage.setItem('transcript_finish',false);
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
