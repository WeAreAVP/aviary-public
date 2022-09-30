/**
 * Interviews Manager
 *
 * @author Furqan Wasi <furqan@weareavp.com>
 *
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 *
 */
"use strict";

function InterviewManager() {
    let that = this;
    let appHelper = new App();
    let notesEvent;
    let notesEventColor;
    that.ids_session_raw = [];
    that.ids_session = [];
    that.current_interview_edit = 0;
    that.has_error_update = false;
    that.interview_transcript_id = 0;
    this.initialize = function () {
        bindEvents();
    };

    this.initializeSync = function () {
        $(".translation_transcript, .main_transcript").click(function(){
            $('.'+$(this).data('opposite')).removeClass('btn-primary').addClass('btn-outline-secondary');
            $(this).addClass('btn-primary').removeClass('btn-outline-secondary');
            $('.'+$(this).data('showdiv')).removeClass('d-none');
            $('.'+$(this).data('hidediv')).addClass('d-none');
        });
      
        $('.single_word_transcript')
          .mouseenter( function(){
            $(this).addClass('text-dark');
            $(this).addClass('bg-success');
            $(this).addClass('border');
            $(this).addClass('rounded');
          }).mouseleave( function(){
            $(this).removeClass('bg-success');
            $(this).removeClass('text-dark');
            $(this).removeClass('border');
            $(this).removeClass('rounded');
          });
      
          $('.single_point_transcript')
          .mouseenter( function(){
            $(this).addClass('bg-light');
            $(this).addClass('border');
            $(this).addClass('rounded');
          }).mouseleave( function(){
            $(this).removeClass('bg-light');
            $(this).removeClass('border');
            $(this).removeClass('rounded');
          });
    };

    this.initializeTable = function () {
        
        let config = {
            responsive: true,
            processing: true,
            serverSide: true,
            pageLength: 100,
            bInfo: true,
            destroy: true,
            bLengthChange: true,
            lengthMenu: lengthMenuValues,
            scrollX: true,
            scrollCollapse: false,
            fixedColumns:   {
                leftColumns: 0,
                rightColumns: $('#interviews_data_table').data('rightrow')
            },
            pagingType: 'simple_numbers',
            'dom': "<'row'<'col-md-6 d-flex'f><'col-md-6'p>>" +
                "<'row'<'col-md-12'tr>>" +
                "<'row'<'col-md-6'li><'col-md-6'p>>",
            language: {
                info: 'Showing _START_ - _END_ of _TOTAL_',
                infoFiltered: '',
                zeroRecords: 'No Records found.',
                lengthMenu: " _MENU_ "
            },
            ajax: {
                url: $('#interviews_data_table').data('url'),
                type: 'POST'
            },
            columnDefs: [
                {orderable: false, targets: -1}, {orderable: false, targets: 0}
            ],
            drawCallback: function (settings) {
                try {
                    that.datatableInitDraw(settings);
                   
                } catch (e) {

                }
                if (typeof interviews_manager.interview_transcript_id != 'undefined' && interviews_manager.interview_transcript_id != 0) {
                    appHelper.show_loader();
                    setTimeout(function(){
                        $('#interview_tupload_' + interviews_manager.interview_transcript_id ).click();    
                        appHelper.hide_loader();
                    }, 2000);
                }
            },
            initComplete: function (settings) {
                try {
                    that.datatableInitComplete(settings);
                } catch (e) {

                }
            }
        };
        appHelper.serverSideDatatable('#interviews_data_table', that, config, $('#interviews_data_table').data('url'));
        $('#sortable_resource_columns').sortable({
            handle: '.handle'
        });

        $('#update_column_status').on('click', function () {
            var anyBoxesChecked = false;
            $('.all_fields_identifier').each(function () {
                if ($(this).is(":checked")) {
                    anyBoxesChecked = true;
                }
            });
            if (anyBoxesChecked) {
                that.update_resource_columns();
            } else {
                jsMessages('danger', 'Select at-least one field and try again!');
            }
        });

        $('.check_all_fields, .uncheck_all_fields').on('click', function () {
            $('.' + $(this).data('search-field')).prop('checked', $(this).data('search-status'));
        });
        initDeletePopup();
        initNotesPopup();
        bulk_option_selection();
        initImportXmlFile();
        updateTranscriptInfo();
        assignUser();
        bulkAssignUser();
    };

    const updateTranscriptInfo = function() {
        let updateClass = '#update_transcript_inteviews';
        $("#interview_transcript_translation, #interview_transcript_associated_file").change(function(){
            if($(this).attr('id') == 'interview_transcript_associated_file') {
                    $('#selected_file_associated_file').text((this).files[0].name);
                    $('#selected_file_associated_file').removeClass('d-none');
                } else {
                    $('#selected_file_translation').text((this).files[0].name);
                    $('#selected_file_translation').removeClass('d-none');
        
                }
        });
    };
    
    this.datatableInitDraw = function () {
        $('[data-toggle="tooltip"]').tooltip();
        setTimeout(function () {
            if (typeof that.resource_bulk_edit != "undefined") {
                that.resource_bulk_edit.re_init_bulk();
            }
            $('.select_all_checkbox_interview').prop('checked', false);
            $('.select_all_checkbox_interview').unbind('click');
            $('.select_all_checkbox_interview').click(function () {
                let all_ids = [];
                if (this.checked) {
                    $(".interviews_selections").prop('checked', true);
                } else {
                    $(".interviews_selections").prop('checked', false);
                }

                $('.interviews_selections').each(function () {
                    let current_id = $(this).data('id').toString();
                    if (typeof that.ids_session == 'undefined' || that.ids_session.length <= 0) {
                        that.ids_session = [];
                    }
                    all_ids.push(current_id);
                    if (this.checked) {
                        let index = that.ids_session.indexOf(current_id);
                        if (index <= 0) {
                            that.ids_session.push(current_id);
                        }
                    } else {
                        let index = that.ids_session.indexOf(current_id);
                        if (index > -1) {
                            that.ids_session.splice(index, 1);
                        }
                    }
                });

                let data = {
                    action: 'bulk_resource_list',
                    ids: all_ids,
                    bulk: 1,
                    type: 'interview_bulk'
                };

                if (this.checked) {
                    data.status = 'add';
                } else {
                    data.status = 'remove';
                }
                appHelper.classAction($(this).data().url, data, 'JSON', 'POST', '', that, true);
            });

            $(".interviews_selections").unbind('change');
            $(".interviews_selections").bind('change', function () {
                let data = {
                    action: 'bulk_resource_list',
                    bulk: 0,
                    type: 'interview_bulk'
                };
                let current_id = $(this).data().id.toString();
                if (this.checked) {
                    data.status = 'add';
                    that.ids_session.push(current_id);
                } else {
                    var index = that.ids_session.indexOf(current_id);
                    if (index > -1) {
                        that.ids_session.splice(index, 1);
                    }
                    data.status = 'remove';
                }
                appHelper.classAction($(this).data().url, data, 'JSON', 'GET', '', that, true);
                $('.select_all_checkbox_interview').prop('checked', false);
            });
            $(".bluk-edit-btn").unbind('click');
            $('.bluk-edit-btn').on('click', function () {
                if (that.ids_session.length <= 0) {
                    jsMessages('danger', 'Please select interviews before doing bulk operations.');
                } else {
                    $('.bulk-edit-modal').modal();
                }
            });
            initUploadPopup();
        }, 500);

    }

    const bulk_option_selection = function () {
        $('.bulk_operation_interviews').change(function () {
            update_bulk_edit_view($(this).val());
        });

        $('.bulk-edit-submit').unbind('click');
        $('.bulk-edit-submit').on('click', function () {
            appHelper.classAction($(this).data('url'), {
                action: 'fetch_bulk_edit_resource_list',
                type: 'interviews'
            }, 'HTML', 'GET', '', that);
        });
    };

    this.fetch_bulk_edit_resource_list = function (response) {
        $('.bulk-edit-review-content-resource-file').html('');
        $('.review_resources_file_bulk').DataTable().destroy();
        $('.bulk-edit-review-content-resource-file').html(response);
        $('.review_resources_file_bulk').DataTable({
            pagingType: 'simple_numbers',
            'dom': "<'row'<'col-md-6 d-flex'f><'col-md-6'p>>" +
                "<'row'<'col-md-12'tr>>" +
                "<'row'<'col-md-6'li><'col-md-6'p>>",
            pageLength: 10,
            bLengthChange: false,
            destroy: true,
            bInfo: true,
        });
    };

    const update_bulk_edit_view = function (selected_type) {
        $('.operation_content').addClass('d-none');
        $('.bulk-edit-submit').prop('disabled', false)
        if (selected_type == 'download_xml') {
            $('.export_xml_content').removeClass('d-none');
            $('#bulk_edit_type_of_bulk_operation').val('download_xml');
            $('#confirm_msg_pop_bulk').html(' export the interviews listed below as XML.');
        } else if (selected_type == 'bulk_delete') {
            $('.bulk_delete_content').removeClass('d-none');
            $('#bulk_edit_type_of_bulk_operation').val('bulk_delete');
            $('#confirm_msg_pop_bulk').html(' delete the interviews listed below.');
        }
        else if (selected_type == 'mark_restricted' || selected_type == 'mark_not_restricted') {
            $('.export_xml_content').addClass('d-none');
            $('.bulk_delete_content').addClass('d-none');
            $('#bulk_edit_type_of_bulk_operation').val(selected_type);
            $('#confirm_msg_pop_bulk').html(' change the use restrictions for the interviews listed below');
        }
        else if (selected_type == 'mark_online' || selected_type == 'mark_ofline') {
            $('.export_xml_content').addClass('d-none');
            $('.bulk_delete_content').addClass('d-none');
            $('#bulk_edit_type_of_bulk_operation').val(selected_type);
            $('#confirm_msg_pop_bulk').html(' change the online status for the interviews listed below');
        }
        else if (selected_type == 'ohms_assigned_users') {
            $('.bulk-edit-submit').prop('disabled', true)
            $('.ohms_assign_users_content').removeClass('d-none');
            $('.export_xml_content').addClass('d-none');
            $('#bulk_edit_type_of_bulk_operation').val(selected_type);
            $('#confirm_msg_pop_bulk').html(' assign OHMS user for the interviews listed below');
        }
    };

    this.bulk_resource_list_clear_all = function () {
        location.reload();
    };

    const updateCount = function (number_selected) {
        emptyCount();
        if (number_selected > 0) {
            let text = (number_selected > 1) ? 'Interviews' : 'Interview';
            $('#interviews_data_table_filter label').append('<span style="color:#204f92" class="ml-10px font-weight-bold" id="resource_selected"> <strong  class="font-size-16px ">' + number_selected + '</strong> ' + text + ' selected | </span> ');
            $('#interviews_data_table_filter label').append('<a href="javascript://" id="clear_all_selection">Clear selected</a>');
            $('#interviews_data_table_filter label').append('<span id="delete_all_selection_sp"> | <a href="javascript://" id="delete_all_selection">Bulk Delete</a></span>');
            $('#number_of_bulk_selected_popup').html('<span style="color:#204f92" class="ml-10px font-weight-bold" id="resource_selected">  ( <strong  class="font-size-16px ">' + number_selected + '</strong> ' + text + ' will be affected ) </span>');
        }
        $('#clear_all_selection').unbind('click');
        $('#clear_all_selection').bind('click', function () {
            var data = {
                action: 'bulk_resource_list_clear_all',
                ids: that.ids_session,
                bulk: 1,
                status: 'remove'
            };

            that.ids_session = [];
            updateCount(that.ids_session.length);
            appHelper.classAction($('.select_all_checkbox_interview').data().url, data, 'JSON', 'GET', '', that, false);
        });

        $('#delete_all_selection').unbind('click');
        $('#delete_all_selection').bind('click', function () {
            appHelper.classAction($('.select_all_checkbox_interview').data().bulk_delete, {
                action: 'fetch_bulk_edit_resource_list',
                type: 'interviews'
            }, 'HTML', 'GET', '', that);
            $('.bulk_operation_interviews')[0].selectize.setValue('bulk_delete');
            $('.bulk-edit-review-modal').modal()

        });
    };

    const emptyCount = function () {
        $('#resource_selected').remove();
        $('#number_of_bulk_selected_popup').html('');
        $('#clear_all_selection').remove();
        $('#delete_all_selection_sp').remove();
        $('#delete_all_selection').remove();
    };

    this.bulk_resource_list = function (response) {
        emptyCount();
        let ids = response[0]['ids'].split(',');
        if (ids != '' && ids.length > 0) {
            updateCount(ids.length);
        }
    };

    this.update_resource_columns = function () {
        let metadata_fields_status = $('#sortable_resource_columns').sortable('toArray');
        let info = {};
        $.each(metadata_fields_status, function (index, value) {
            info[index] = {};
            info[index]['system_name'] = value
            info[index]['table_display'] = $('#' + value + '_status').prop('checked');
            info[index]['table_sort_order'] = index
            if ($('.all_fields_search_identifier#' + value).length > 0) {
                info[index]['table_search'] = $('.all_fields_search_identifier#' + value).prop('checked');
            } else {
                info[index]['table_search'] = false;
            }
        });

        let data = {
            js_action: 'updateSort',
            action: 'updateSort',
            info: info,
            options: 'interview_table_org',
            type: 'interview_fields'
        };

        appHelper.classAction($('#update_sort_information').data('url'), data, 'JSON', 'POST', '', that);
    };

    this.updateSort = function () {
        jsMessages('success', 'Information updated successfully.');
        setTimeout(function () {
            location.reload();
        }, 2000);
    };

    const bindEvents = function () {
        let val = $('#interviews_interview_media_duration').val();
        $('#interviews_interview_media_duration').timepicker({
            timeFormat: 'HH:mm:ss',
            interval: 1,
            dynamic: true,
            zindex: 999,
            startTime: new Date(0, 0, 0, 0, 0, 0),
            maxHour: 200,
            defaultTime: '00:00:00',
            dropdown: true,
            scrollbar: true
        }).val(val);
        $('#interviews_interview_interview_date').datepicker();
        let containerRepeatManager = new ContainerRepeatManager();
        containerRepeatManager.makeContainerRepeatable(".add_keywords", ".remove_keywords", '.container_keywords_inner', '.container_keywords', '.keywords');
        containerRepeatManager.makeContainerRepeatable(".add_subjects", ".remove_subjects", '.container_subjects_inner', '.container_subjects', '.subjects');
        containerRepeatManager.makeContainerRepeatable(".add_interviewee", ".remove_interviewee", '.container_interviewee_inner', '.container_interviewee', '.interviewee');
        containerRepeatManager.makeContainerRepeatable(".add_interviewer", ".remove_interviewer", '.container_interviewer_inner', '.container_interviewer', '.interviewer');
        containerRepeatManager.makeContainerRepeatable(".add_format", ".remove_format", '.container_format_inner', '.container_format', '.format');
        initDeletePopup();
        initNotesPopup();
        initImportXmlFile();
        document_level_binding_element('#interviews_interview_media_host', 'change', function () {
            manageFieldsMedia($(this).val());
        });
        manageFieldsMedia($('#interviews_interview_media_host').val());
        assignUser();
        bulkAssignUser();
    };

    const manageFieldsMedia = function (value) {
        let listing = {
            'Other': ['.media_url_embed'],
            'Avalon': ['.avalon_target_domain', '.embed_code', '.media_url_embed'],
            'Aviary': ['.media_url_embed'],
            'Brightcove': ['.media_host_account_id', '.media_host_player_id', '.media_host_item_id'],
            'Kaltura': ['.embed_code'],
            'SoundCloud': ['.embed_code'],
            'Vimeo': ['.embed_code'],
            'YouTube': ['.embed_code', '.media_url_embed'],
        }
        if (typeof listing[value] != 'undefined') {
            $('.dynamic_control_interview').addClass('d-none');
            $.each(listing[value], function (index, val) {
                $(val).removeClass('d-none');
            });
        }
    };

    const initDeletePopup = function () {

        document_level_binding_element('.interview_delete', 'click', function () {
            $('#modalPopupBody').html('Are you sure you want to delete this Interview? There is no undoing this action.');
            $('#modalPopupTitle').html('Delete "' + $(this).data().name + '" Interview');
            $('#modalPopupFooterYes').attr('href', $(this).data().url);
            $('#modalPopup').modal('show');
        });
    };
    const setNotesResponse = function (response) {
        let html = ""
        response.data.forEach(element => {
            html = html + '<div>' + element.note + '</div>';
            html = html + '<div class="d-flex mb-3"><div class="custom-checkbox mr-3"><input type="radio" class="unresolve notes_status" name="status_' + element.id + '" id="unresolve_' + element.id + '" value="0" ' + (element.status ? "" : 'checked="checked"') + ' data-id="' + element.id + '" data-status="0" data-url="' + notesEvent.target.getAttribute("data-updateurl") + '" ></input><label for="unresolve_' + element.id + '">Unresolved</label></div>';
            html = html + '<div class="custom-checkbox mr-3"><input type="radio" class="resolve notes_status" name="status_' + element.id + '" id="resolve_' + element.id + '" value="1" ' + (element.status ? 'checked="checked"' : "") + ' data-id="' + element.id + '" data-status="1" data-url="' + notesEvent.target.getAttribute("data-updateurl") + '" ></input><label for="resolve_' + element.id + '">Resolved</label></div></div>';
        });
        html = (response.length == 0 ? "There are currently no notes associated with this interview." : html);
        $('#listNotes').html(html);
    }
    const clearImportXmlFile = function () {
        $("#import_xml_file").val(null).trigger("change");
        $('.import-xml-file-section').show();
        $('.import-file-confirmation').hide();
        $('#status_complete').prop("checked", false);
        $('#import_file_name').html('');
        $('#import_xml_btn').text('Import');
        $('#import_xml_btn').unbind();
    }
    const initImportXmlFile = function () {
        $('#import_xml_modal').on('hidden.bs.modal', function () {
            $('.close-import-popup').attr('data-dismiss','modal').text('Close');

            clearImportXmlFile();
        })
        $("#import_file_name").html("");
        $('#import_xml_file').fileupload({
            url: $('#import_xml_file').data('url'),
            type: 'POST',
            formData: {status: $('#status_complete').is(":checked")},
            sequentialUploads: true,
            singleFileUploads: false,
            acceptFileTypes: /^text\/(xml)$/i,
            dataType: 'json',
            autoUpload: false,
            submit: function (e, data) {
                data.formData = {status: ($('#status_complete').is(":checked") ? "3" : "-1")};
                return true;
            },
            add: function (e, data) {
                $.each(data.files, function (index, file) {
                    let filename = file.name;
                    let fileExt = filename.split('.').pop();
                    if ((file.type != '' && file.type != 'text/xml' && file.type != 'text/csv' && file.type != 'application/xml' && file.type != 'application/vnd.ms-excel') || (file.type == '' && fileExt != 'xml')) {
                        jsMessages('danger', 'Only XML or CSV file allowed.');
                        return false;
                    } else {
                        $("#import_file_name").append("Selected File: " + file.name + "<br/>");
                        $('.import-xml-file-section').hide();
                        $('.import-file-confirmation').show();
                        $('#import_xml_btn').text('Yes');
                        $('.close-import-popup').removeAttr('data-dismiss').text('No');
                        $('#import_xml_btn').unbind("click").bind("click", function () {
                            $(this).prop("disabled", true);
                            data.submit();
                            $(this).html("Processing...");
                        });
                        $('.close-import-popup').unbind("click").bind("click", function () {
                            clearImportXmlFile();
                            $('.import-xml-file-section').show();
                        });
                    }
                });

            },
            progressall: function (e, data) {
                var progress = parseInt(data.loaded / data.total * 100, 10);
                $('#progress_import .progress-bar').css(
                    "width",
                    progress + "%"
                );
            },
            done: function (e, data) {
                let response = data.response().result;
                if (response.error) {
                    jsMessages('danger', response.message);
                    $('#progress_import .progress-bar').css("width", "0%");
                    $('.import-xml-file-section').show();
                    $('.import_csv_note').show();
                    $('.import-file-confirmation').hide();
                    $('#import_xml_btn').prop("disabled", false);
                    $('#import_xml_btn').html("Import");

                } else {
                    jsMessages('success', 'XML or CSV imported successfully.');
                    setTimeout('window.location.reload();', 5000);
                }

            }
        });
    };

    this.transcriptSync = function (response) {
    
        if (response.response != null && typeof response.response != 'undefined') {
            $('#modalPopupSyncBody').html(''); 
            $('#modalPopupSyncBody').append('<h1 style="color: red;"> Main Transcript </span>' );
            if (typeof response.response.data_main != 'undefined' ) {
            $.each(response.response.data_main, function(single_response, obj){
                $('#modalPopupSyncBody').append('<span style="color: blue;">' + obj.start_time + '</span>' );    
                $('#modalPopupSyncBody').append('<br/>');    
                $('#modalPopupSyncBody').append(obj.text);    
                $('#modalPopupSyncBody').append('<br/>');    
                $('#modalPopupSyncBody').append('<span style="color: blue;">' + obj.end_time + '</span>' );    
                $('#modalPopupSyncBody').append('<hr/><hr/><hr/><hr/><hr/>');    
            });
        }
        if (typeof response.response.data_translation != 'undefined' ) {
            $('#modalPopupSyncBody').append('<h1 style="color: red;"> Translation Transcript </span>' );
            $.each(response.response.data_translation, function(single_response, obj){
                $('#modalPopupSyncBody').append('<span style="color: blue;">' + obj.start_time + '</span>' );    
                $('#modalPopupSyncBody').append('<br/>');    
                $('#modalPopupSyncBody').append(obj.text);    
                $('#modalPopupSyncBody').append('<br/>');    
                $('#modalPopupSyncBody').append('<span style="color: blue;">' + obj.end_time + '</span>' );    
                $('#modalPopupSyncBody').append('<hr/><hr/><hr/><hr/><hr/>');    
            });
        }
            $('#modalPopupSync').modal('show');
        }
        
    };

    const initUploadPopup = function () {
        document_level_binding_element(".interview_transcript_upload", 'click', function (e) {
            $('#selected_file_translation').text('');
            $('#selected_file_associated_file').text('');
            that.current_interview_edit = $(this).data().url;
            $("#interviewTranscriptForm").attr("action", $(this).data().url);
            let data = {
                action: 'transcriptInformation',
                js_action: 'transcriptInformation',
            };
            appHelper.classAction($(this).data().url, data, 'JSON', 'GET', '', that, true);
        });
    }

    this.transcriptInformation = function (response) {
        if (response.response != null && typeof response.response != 'undefined' && typeof response.response[0] != 'undefined' && response.response[0]) {
            let associatedFileName = response.response[0]['associated_file_file_name'];
            if (associatedFileName) {
                $('#selected_file_associated_file').text(associatedFileName);
                $('#selected_file_associated_file').removeClass('d-none');
            }
            if(typeof response.response[1] != 'undefined' && response.response[1] != null ){
                let translationFileName = response.response[1]['associated_file_file_name'];
                if (typeof translationFileName != 'undefined' && translationFileName ) {
                    $('#selected_file_translation').text(translationFileName);
                    $('#selected_file_translation').removeClass('d-none');
                }
            }
            let noTranscript = response.response[0]['no_transcript'];
            $('#no-transcript-checkbox').prop('checked', false);
            if (noTranscript) {
                $('#no-transcript-checkbox').prop('checked', noTranscript)
            }

            let timecodeIntervals = response.response[0]['timecode_intervals']
            if (timecodeIntervals) {
                $('#interview_transcript_timecode_intervals')[0].selectize.setValue(timecodeIntervals);
            } else {
                $('#interview_transcript_timecode_intervals')[0].selectize.setValue('1');
            }
        }

        $('#modalPopupUpload').modal('show');
    };

    const initNotesPopup = function () {
        document_level_binding_element(".interview_notes", 'click', function (e) {
            notesEvent = e;
            $("#notesForm").attr("action", $(this).data().url);
            $.ajax({
                url: $(this).data().url,
                type: 'GET',
                dataType: 'json',
                success: function (response) {
                    setNotesResponse(response);
                    if (response.color) notesEventColor = response.color;
                    $('#note').val("");
                    $('#modalPopupNotes').modal('show');
                },
            });
        });
        document_level_binding_element(".notes_status", 'click', function (e) {
            let formData = {
                'note_id': e.target.getAttribute("data-id"),
                'status': e.target.getAttribute("data-status")
            };
            $.ajax({
                url: e.target.getAttribute("data-url"),
                data: formData,
                type: 'POST',
                dataType: 'json',
                success: function (response) {
                    if (response.color) notesEventColor = response.color;
                },
            });
            jsMessages('success', 'Note updated successfully.');
        });
        $("#note").on("mousedown mouseup click focus", function (e) {
            $('.error_note').html("");
        })
        $('#modalPopupNotes').on('hidden.bs.modal', function () {
            $('#interview_note_' + notesEvent.target.getAttribute("data-id")).removeClass("text-danger text-success text-secondary");
            $('#interview_note_' + notesEvent.target.getAttribute("data-id")).addClass(notesEventColor);
            notesEventColor = "";
        });
        $(document).on("submit", "#notesForm", function (e) {
            e.preventDefault();
            let form = $(this);
            let url = form.attr("action");
            let serializedData = form.serialize();
            if ($('#note').val() === "") {
                $('.error_note').html("Please type a note before clicking the Add Note button.");
            } else {
                $.ajax({
                    type: "POST",
                    url: url,
                    data: serializedData,
                    success: function (response) {
                        $('#note').val("");
                        $('.errors').html("");
                        setNotesResponse(response);
                        jsMessages('success', 'Note added successfully.');
                        if (response.color) notesEventColor = response.color;
                    },
                    error: function (response, status, error) {
                        let info = jQuery.parseJSON(response.responseText);
                        for (const property in info.errors) {
                            $('.error_' + property).html(property.toUpperCase() + ' ' + info.errors[property]);
                        }
                    }
                });
            }
        })

    };

    this.handlecallback = function (response, container, requestData) {
        try {
            eval('this.' + requestData.action + '(response,container,requestData)');
        } catch (err) {
            console.log(err);
        }
    };

    const assignUser = () => {
        document_level_binding_element(".assign_user", 'change', function (e) {
            let userId = e.target.value
            let callUrl = $(e.target).attr('data-call_url')
            if(userId){
                $.ajax({
                    url: callUrl +'/' + e.target.value,
                    type: 'GET',
                    dataType: 'json',
                    success: function (response) {
                        if (response.success) {
                            jsMessages('success', response.message);
                        } else {
                            jsMessages('error', response.message);
                        }
                    },
                });
            }
        });
    }

    this.keywordField = (keys, selectedKeys) => {
        new Tokenfield({
            el: document.querySelector('.tokenfield_keywords'), // Attach Tokenfield to the input element with class "text-input"
            items: keys,
            matchStart: true,
            minChars: 1,
            newItems: false,
            itemName: 'keywords',
            setItems: selectedKeys
          });
    }

    this.searchField = (keys, selectedKeys) => {
        new Tokenfield({
            el: document.querySelector('.tokenfield_subjects'), // Attach Tokenfield to the input element with class "text-input"
            items: keys,
            matchStart: true,
            minChars: 1,
            newItems: false,
            itemName: 'subjects',
            setItems: selectedKeys
        });
    }

    const bulkAssignUser = () => {
        document_level_binding_element(".bulk_assign_user", 'change', function (e) {
            let userId = e.target.value
            if (userId) {
                $('.bulk-edit-submit').prop('disabled', false)
            } else {
                $('.bulk-edit-submit').prop('disabled', true)
            }
        });
    }
}
