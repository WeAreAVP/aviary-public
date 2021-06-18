/**
 * Index Table Management
 *
 * @author Zaheer <zaheer@weareavp.com>
 *
 */
"use strict";

function IndexTable() {

    var that = this;
    this._bulk_edit;
    this.dataTableObj;
    this._table_column_detail = {};
    this.app_helper = {};
    this._list_bulk_edit;


    this.initialize = function (_table_column_detail, _list_bulk_edit) {
        that.app_helper = new App();

        that._table_column_detail = _table_column_detail;
        that._list_bulk_edit = _list_bulk_edit;
        that._bulk_edit = new FileIndexBulkEdit(that._list_bulk_edit);

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

    };
    this.handlecallback = function (response, container, requestData) {
        try {
            eval('this.' + requestData.action + '(response,container,requestData)');
        } catch (err) {
            console.log(err);
        }
    };

    this.outSourceDataTable = function (called_from, caller, additionalData, tableName = 'indexes_datatable') {
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
            tableName = 'indexes_datatable';
        }

        let _table_column_detail = JSON.parse(that._table_column_detail);
        let dataTableElement = $('#' + tableName);
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
                    leftColumns: _table_column_detail.number_of_column_fixed > 0 ? parseInt(_table_column_detail.number_of_column_fixed, 10) + 1 : 0,
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
                    zeroRecords: 'No Index found.',
                    lengthMenu: " _MENU_ "
                },
                order: [[1, 'asc']],
                columnDefs: [
                    {orderable: false, targets: -1}, {orderable: false, targets: 0}
                ],
                ajax: {
                    url: dataTableElement.data('url'),
                    type: 'POST',
                    data: function (d) {
                        d.called_from = called_from;
                        d.additionalData = additionalData;
                    }
                },
                drawCallback: function (settings) {
                    if (called_from == 'permission_group') {
                        $('#media_files_datatable_length').addClass('d-none');
                        $('.add_to_index_group').unbind('click');
                        $('.add_to_index_group').on('click', function () {
                            let permission_group = new PermissionGroup();
                            let response = permission_group.outsourceAddToken('permission_group_indexes', $(this).data());
                            if (response) {
                                jsMessages('success','Index added to permission group');
                            }
                        });
                    } else {
                        initDeletePopup();
                        setTimeout(function () {
                            that._bulk_edit.re_init_bulk();
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
                    if (called_from != 'permission_group') {
                        initBulkEdit();
                    }
                }
            });
        }
    };

    const initBulkEdit = function () {
        that._bulk_edit.initialize();
    };

    const initDeletePopup = function () {
        $('.index_delete').click(function () {
            $('#modalPopupTitle').html('Delete "' + $(this).data().name + '" Index');
            $('#modalPopupBody').html('Are you sure you want to delete this index? There is no undoing this action.');
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
            data['columns_search_status'][index] = {value: $(this).attr('id'), status: $(this).prop('checked')};
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
