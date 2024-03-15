/**
 * Collection Resource Table Management
 *
 * @author Fayzan Wasim <fayzan@weareavp.com>
 *
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 *
 */
"use strict";

function CollectionMediaTable() {

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
        bindings();
        importCsvFile();
        manageTable();
    };

    const bindings = function () {
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
    };

    const importCsvFile = function () {
        $('#import_csv_file').fileupload({
            url: $('#import_csv_file').data('url'),
            type: 'POST',
            dataType: 'json',
            autoUpload: false,
            beforeSend(xhr) {
                xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
            },
            add: function (e, data) {

                $.each(data.files, function (index, file) {

                    let filename = file.name;
                    let fileExt = filename.split('.').pop();
                    if ((file.type != '' && file.type != 'text/csv' && file.type != 'application/vnd.ms-excel') || (file.type == '' && fileExt != 'csv')) {
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
                    jsMessages('success', 'CSV import queued successfully. You will be notified via email once the import is completed.');
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

    this.outSourceDataTable = function (called_from, caller, additionalData, tableName = 'collection_media_datatable') {
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
            tableName = 'collection_media_datatable';
        }
        let rightColumns = 1;
        let dataTableElement = $('#' + tableName);

        let ajax_url = dataTableElement.data('url');
        let sorters = [
            {orderable: false, targets: -1}, {orderable: false, targets: 0}
        ];

        let resource_table_column_detail = JSON.parse(that.resource_table_column_detail);
        if (dataTableElement.length > 0) {
            that.dataTableObj = dataTableElement.DataTable({
                responsive: true,
                processing: true,
                serverSide: true,
                pageLength: pageLength,
                scrollX: true,
                scrollCollapse: false,
                paging: true,
                searchDelay: 800,
                fixedColumns: {
                    leftColumns: resource_table_column_detail.number_of_column_fixed > 0 ? parseInt(resource_table_column_detail.number_of_column_fixed, 10) + 1 : 0,
                    rightColumns: 1
                },
                order: [[1, 'asc']],
                columnDefs: [
                    { orderable: false, targets: -1 }, { orderable: false, targets: 0 }
                ],
                ajax: {
                    url: dataTableElement.data('url'),
                    type: 'POST',
                    data: function (d) {
                        d.called_from = called_from;
                        d.additionalData = additionalData;
                    },
                    beforeSend(xhr) {
                        xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
                    },
                    dataSrc: function ( json ) {
                        //Make your callback here.
                        if ( typeof that.resource_bulk_edit != 'undefined') {
                            that.resource_bulk_edit.getTotalCount(json.recordsTotal)
                        }
                        return json.data;
                    }
                },
                drawCallback: function (settings) {
                    $('#collection_media_datatable_length').parent().addClass('d-none');
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
                    if (called_from != 'permission_group') {
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
                    }
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
            data['columns_status'][index] = { value: value, status: $('#' + value + '_status').prop('checked') };
        });

        $.each($('.all_fields_search_identifier'), function (index) {
            data['columns_search_status'][index] = { value: $(this).attr('id'), status: $(this).prop('checked') };
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

    this.updateSort = function () {
        jsMessages('success', 'Information updated successfully.');
        setTimeout(function () {
            location.reload();
        }, 2000);
    }

    this.update_media_column_sort = function (response, container) {

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
