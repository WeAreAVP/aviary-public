/**
 * Interviews Manager
 *
 * @author Furqan Wasi <furqan@weareavp.com>
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 */
"use strict";

function InterviewManager() {
    let that = this;
    let appHelper = new App();
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
    }

    const initDeletePopup = function () {

        document_level_binding_element('.interview_delete', 'click', function () {
            $('#modalPopupBody').html('Are you sure you want to delete this Interview? There is no undoing this action.');
            $('#modalPopupTitle').html('Delete "' + $(this).data().name + '" Interview');
            $('#modalPopupFooterYes').attr('href', $(this).data().url);
            $('#modalPopup').modal('show');
        });
    };
    this.handlecallback = function (response, container, requestData) {
        try {
            eval('this.' + requestData.action + '(response,container,requestData)');
        } catch (err) {
            console.log(err);
        }
    };
}
