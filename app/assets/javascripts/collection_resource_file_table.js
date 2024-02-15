/**
 * Collection Resource Table Management
 *
 * @author Furqan Wasi <furqan@weareavp.com>
 *
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 *
 */
"use strict";

function CollectionResourceFileTable() {

    var that = this;
    this.resource_bulk_edit;
    this.dataTableObj;
    this.resource_table_column_detail = {};
    this.app_helper = {};
    this.resource_list_bulk_edit;


    this.initialize = function (resource_table_column_detail, resource_list_bulk_edit) {
        that.app_helper = new App();
        that.collection_resource_table = new CollectionResourceTable();
        that.resource_table_column_detail = resource_table_column_detail;
        that.resource_list_bulk_edit = resource_list_bulk_edit;
        that.resource_bulk_edit = new ResourceBulkFileEdit(that.resource_list_bulk_edit);

        initDataTable();
        $('.manage-resource-columns-btn').on('click', function () {
            $('#manage_resource_columns_modal').modal();
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
                jsMessages('danger', 'Select at-least one metadata field and try again!');
            }
        });

        $('#sortable_resource_columns').sortable({
            handle: '.handle'
        });

        $('.check_all_fields, .uncheck_all_fields').on('click', function () {
            $('.' + $(this).data('search-field')).prop('checked', $(this).data('search-status'));
        });
        manageTable();
    };
    this.handlecallback = function (response, container, requestData) {
        try {
            eval('this.' + requestData.action + '(response,container,requestData)');
        } catch (err) {
            console.log(err);
        }
    };

    const initDataTable = function () {
        let resource_table_column_detail = JSON.parse(that.resource_table_column_detail);
        let dataTableElement = $('#collection_resource_datatable');
        if (dataTableElement.length > 0) {
            that.dataTableObj = dataTableElement.DataTable({
                responsive: true,
                processing: true,
                serverSide: true,
                pageLength: pageLength,
                scrollX: true,
                scrollCollapse: false,
                paging: true,
                fixedColumns: {
                    leftColumns: resource_table_column_detail.number_of_column_fixed > 0 ? parseInt(resource_table_column_detail.number_of_column_fixed, 10) + 1 : 0,
                    rightColumns: 1
                },
                destroy: true,
                bInfo: true,
                pagingType: 'simple_numbers',
                'dom': "<'row'<'col-md-6 d-flex'f><'col-md-6'p>>" +
                    "<'row'<'col-md-12'tr>>" +
                    "<'row'<'col-md-6'li><'col-md-6'p>>",
                bLengthChange: true,
                lengthMenu: lengthMenuValues,
                language: {
                    info: 'Showing _START_ - _END_ of _TOTAL_',
                    infoFiltered: '',
                    zeroRecords: 'No Resource found.',
                    lengthMenu: " _MENU_ "
                },
                order: [[ 1, 'asc' ]],
                columnDefs: [
                    {orderable: false, targets: -1}, {orderable: false, targets: 0}
                ],
                ajax: {
                    url: dataTableElement.data('url'),
                    type: 'POST',
                    beforeSend(xhr) {
                        xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
                    },
                    dataSrc: function ( json ) {
                        //Make your callback here.
                        that.resource_bulk_edit.getTotalCount(json.recordsTotal)
                        return json.data;
                    }
                },
                drawCallback: function (settings) {
                    initDeletePopup();
                    setTimeout(function () {
                        that.resource_bulk_edit.re_init_bulk();
                        $('.select_all_checkbox_resources').prop('checked', false);
                        $('#collection_resource_datatable_filter .form-control').on('keyup', function () {
                            let value = $(this).val();
                            value = value.replace(/[\/\\()|'"*:^~`{}&]/g, '');
                            value = value.replace(/]/g, '');
                            value = value.replace(/[[]/g, '');
                            value = value.replace(/[{}]/g, '');
                            $(this).val(value);
                        });

                    }, 500);

                },
                initComplete: function (settings) {
                    initBulkEdit();
                    var clipboard = new Clipboard('.copy-link');

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
                    fixTable();
                }
            });
        }
    };

    const initBulkEdit = function () {
        that.resource_bulk_edit.initialize();
    };

    const initDeletePopup = function () {
        $('.resource_delete').click(function () {
            $('#modalPopupTitle').html('Delete "' + $(this).data().name + '" Resource');
            $('#modalPopupBody').html('Are you sure you want to delete this resource? This will remove all description, files, indexes, and transcripts associated with this resource from the system. There is no undoing this action.');
            $('#modalPopupFooterYes').attr('href', $(this).data().url);
            $('#modalPopup').modal('show');
        });
    };

    this.update_resource_columns = function () {

        let number_of_column_fixed = $('#number_of_column_fixed').selectize();
        let selectize = number_of_column_fixed[0].selectize;
        let data = {
            action: 'update_resource_column_sort',
            number_of_column_fixed: 0,
            columns_status: {},
            columns_search_status: {}
        };
        data['number_of_column_fixed'] = selectize.getValue();
        $.each($('#sortable_resource_columns').sortable('toArray'), function (index, value) {
            data['columns_status'][index] = {value: value, status: $('#' + value + '_status').prop('checked')};
        });

        $.each($('.all_fields_search_identifier'), function (index) {
            data['columns_search_status'][index] = {value: $(this).data('value'), status: $(this).prop('checked')};
        });

        that.app_helper.classAction($('#manage_resource_columns_modal').data('url'), data, 'JSON', 'POST', '', that);
    };

    this.update_resource_column_sort = function (response, container) {

        if (response.errors) {
            jsMessages('danger', response.message);
        } else {
            jsMessages('success', response.message);
        }
        setTimeout(function () {
            location.reload();
        }, 200)
    };
}
