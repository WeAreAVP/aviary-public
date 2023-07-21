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

function CollectionResourceTable() {

    var that = this;
    this.resource_bulk_edit;
    this.dataTableObj;
    this.resource_table_column_detail = {};
    this.app_helper = {};
    this.resource_list_bulk_edit;
    this.number_of_column_fixed = 0;


    this.initialize = function (resource_table_column_detail, resource_list_bulk_edit, number_of_column_fixed) {
        console.log(resource_table_column_detail);
        if (typeof number_of_column_fixed != 'undefined') {
            this.number_of_column_fixed = number_of_column_fixed;
        }
        that.app_helper = new App();
        that.resource_table_column_detail = resource_table_column_detail;
        that.resource_list_bulk_edit = resource_list_bulk_edit;
        that.resource_bulk_edit = new ResourceBulkEdit(that.resource_list_bulk_edit);
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
        importCsvFile();
    };
    const importCsvFile = function () {
        $('#import_csv_file').fileupload({
            url: $('#import_csv_file').data('url'),
            type: 'POST',
            dataType: 'json',
            autoUpload: false,
            add: function (e, data) {

                $.each(data.files, function (index, file) {
                    if (file.type != 'text/csv' && file.type != 'application/vnd.ms-excel') {
                        jsMessages('danger', 'Only CSV file allowed.');
                        return false;
                    } else {
                        $("#import_file_name").html("Selected File: " + file.name + "<br/>");
                        $('.import-csv-file-section').hide();
                        $('.import_csv_note').hide();
                        $('.import-file-confirmation').show();
                        $('#import_csv_btn').text('Yes');
                        $('.close-import-popup').removeAttr('data-dismiss').text('No');
                        $('#import_csv_btn').unbind("click").bind("click", function () {
                            $(this).prop("disabled", true);
                            data.submit();
                            $(this).html("Processing...");
                        });
                    }
                });

            },
            progressall: function (e, data) {
                var progress = parseInt(data.loaded / data.total * 100, 10);
                $('#progress .progress-bar').css(
                    "width",
                    progress + "%"
                );
            },
            done: function (e, data) {
                let response = data.response().result;
                if (response.error) {
                    jsMessages('danger', result.message);
                    $('#import_csv_btn').prop("disabled", false);
                    $('#import_csv_btn').html("Import");
                } else {
                    jsMessages('success', 'CSV imported successfully.');
                    setTimeout('window.location.reload();', 5000);
                }

            }
        });
    };
    this.handlecallback = function (response, container, requestData) {
        try {
            eval('this.' + requestData.action + '(response,container,requestData)');
        } catch (err) {
            console.log(err);
        }
    };
    this.outSourceDataTable = function (called_from, caller, additionalData, tableName = 'collection_resource_datatable') {
        initDataTable(called_from, caller, additionalData, tableName);
    };

    const initDataTable = function (called_from, caller, additionalData, tableName) {
        if (!called_from && typeof called_from == 'undefined') {
            called_from = '';
        }
        if (!additionalData && typeof additionalData == 'undefined') {
            additionalData = {};
        }

        if (!tableName && typeof tableName == 'undefined') {
            tableName = 'collection_resource_datatable';
        }
        let rightColumns = 1;
        let resource_table_column_detail = that.resource_table_column_detail;
        let dataTableElement = $('#' + tableName);

        let ajax_url = dataTableElement.data('url');
        let sorters = [
            {orderable: false, targets: -1}, {orderable: false, targets: 0}
        ];

        if (called_from == 'permission_group') {
            rightColumns = 1;
            sorters = [];
        }
        if (called_from == 'archiveSpacePreview') {
            rightColumns = 0;
            sorters = [
                {orderable: false, targets: 0}
            ];
        }
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
                    leftColumns: that.number_of_column_fixed > 0 ? parseInt(that.number_of_column_fixed, 10) + 1 : 0,
                    rightColumns: rightColumns
                },
                order: [[1, 'asc']],
                destroy: true,
                bInfo: true,
                pagingType: 'simple_numbers',
                'dom': "<'row'<'col-md-6 d-flex resource-table-length-menu'f><'col-md-6'p>>" +
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
                columnDefs: sorters,
                ajax: {
                    url: ajax_url,
                    type: 'POST',
                    data: function (d) {
                        d.called_from = called_from;
                        d.additionalData = additionalData;
                    },
                    dataSrc: function ( json ) {
                        if (typeof that.resource_bulk_edit != "undefined") {
                            that.resource_bulk_edit.setTotalRecords(json.recordsTotal)
                        }
                        return json.data;
                    }
                },
                drawCallback: function (settings) {
                    if (called_from == 'permission_group' || called_from == 'archiveSpacePreview') {
                        $('#collection_resource_datatable_length').addClass('d-none');
                    }

                    if (called_from == 'playlist_add_resource' && typeof caller != 'undefined') {
                        caller.handler_resource_playlist();
                    } else if (called_from == 'archiveSpacePreview' && typeof caller != 'undefined') {
                        caller.eventCallbackBinding(tableName);
                        caller.syncTableEventCallback(tableName);
                    } else {
                        initDeletePopup();

                        setTimeout(function () {
                            if (typeof that.resource_bulk_edit != "undefined") {
                                that.resource_bulk_edit.re_init_bulk();
                            }
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
                    }

                },
                initComplete: function (settings) {
                    if (settings.aoData.length > 0) {
                        $('.export_btn').toggleClass('d-none');
                    }
                    fixTable();
                    initBulkEdit();
                }
            });
        }
    };

    const initBulkEdit = function () {
        if (typeof that.resource_bulk_edit != "undefined") {
            that.resource_bulk_edit.initialize();
        }
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
        let metadata_fields_status = $('#sortable_resource_columns').sortable('toArray');
        let number_of_column_fixed = $('#number_of_column_fixed').selectize();
        let selectize = number_of_column_fixed[0].selectize;
        let info = {};
        $.each(metadata_fields_status, function (index, value) {
            info[index] = {};
            info[index]['system_name'] = value
            info[index]['resource_table_display'] = $('#' + value + '_status').prop('checked');
            info[index]['resource_table_sort_order'] = index
            if ($('.all_fields_search_identifier#'+value).length > 0 ) {
                info[index]['resource_table_search'] = $('.all_fields_search_identifier#'+value).prop('checked');
            } else {
                info[index]['resource_table_search'] = false;
            }

        });

        let data = {
            js_action: 'updateSort',
            action: 'updateSort',
            info: info,
            fixed_column: selectize.getValue(),
            options: 'resource_table_org',
            type: 'resource_fields'
        };

        that.app_helper.classAction($('#update_sort_information').data('url'), data, 'JSON', 'POST', '', that);
    };

    this.updateSort = function () {
        jsMessages('success', 'Information updated successfully.');
        setTimeout(function () {
            location.reload();
        }, 2000);
    }

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
