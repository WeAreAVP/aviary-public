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
    this.initialize = function () {
        bindEvents();
    };

    this.initializeTable = function () {
        appHelper.serverSideDatatable('#interviews_data_table', that, false, $('#interviews_data_table').data('url'));
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
    };

    this.datatableInitComplete = function () {
        $('[data-toggle="tooltip"]').tooltip();
    }

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
        document_level_binding_element('#interviews_interview_media_host', 'change', function () {
            manageFieldsMedia($(this).val());
        });
        manageFieldsMedia($('#interviews_interview_media_host').val());

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
            html = html + '<div class="custom-checkbox mr-3"><input type="radio" class="resolve notes_status" name="status_' + element.id + '" id="resolve_' + element.id + '" value="1" ' + (element.status ? 'checked="checked"' : "") + ' data-id="' + element.id + '" data-status="1" data-url="' + notesEvent.target.getAttribute("data-updateurl")+ '" ></input><label for="resolve_' + element.id + '">Resolved</label></div></div>';
        });
        html = (response.length == 0 ? "There are currently no notes associated with this interview." : html);
        $('#listNotes').html(html);
    }
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
}
