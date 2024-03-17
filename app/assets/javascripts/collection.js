/**
 * Collection Management
 *
 * @author Nouman Tayyab <nouman@weareavp.com>
 *
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 *
 */

function Collection() {
    selfRBE = this;
    selfRBE.app_helper = {};
    this.dataTableObj;
    this.initialize = function () {
        selfRBE.app_helper = new App();
        if (typeof selfRBE.ids_session == 'undefined' || selfRBE.ids_session.length <= 0) {
            selfRBE.ids_session = [];
        }
        initDataTable();
        bindEvents();
        manageTabs();
        init_tinymce_for_element('#collection_about');

        let display_settings = new DisplaySettings();
        display_settings.init_display_settings('collection');
        selfRBE.re_init_bulk();
    };
    this.fetch_bulk_edit_resource_list = function (response) {
        $('.bulk-edit-review-content').html(response);
        $('.review_resources').DataTable({
            pageLength: 10,
            pagingType: 'simple_numbers',

            bLengthChange: false,
            destroy: true,
            bInfo: true,
        });
    };

    const update_bulk_edit_view = function (selected_type) {
        $('.operation_content').addClass('d-none');
        if (selected_type == 'change_status') {
            $('.bulk_change_status_content').removeClass('d-none');
            $('#bulk_edit_type_of_bulk_operation').val('change_status');
            $('#confirm_msg_pop_bulk').html(' change the access status of the collections listed below');
        }
        if (selected_type == 'change_featured') {
            $('.bulk_change_featured_content').removeClass('d-none');
            $('#bulk_edit_type_of_bulk_operation').val('change_featured');
            $('#confirm_msg_pop_bulk').html(' change the featured status of the collections listed below');
        }
        if (selected_type == 'preferred_default_tab') {
            $('.bulk_preferred_default_tab_content').removeClass('d-none');
            $('#bulk_edit_type_of_bulk_operation').val('preferred_default_tab');
            $('#confirm_msg_pop_bulk').html(' change the preferred default tab of the collections listed below');
        }
        if (selected_type == 'disable_player_and_resource_embed') {
            $('.bulk_disable_player_and_resource_embed_content').removeClass('d-none');
            $('#bulk_edit_type_of_bulk_operation').val('disable_player_and_resource_embed');
            $('#confirm_msg_pop_bulk').html(' change whether player and resource embeding is disabled for the collections listed below');
        }
        if (selected_type == 'click_through') {
            $('.bulk_click_through_content').removeClass('d-none');
            $('#bulk_edit_type_of_bulk_operation').val('click_through');
            $('#confirm_msg_pop_bulk').html(' change the click-through functionality for access requests to private resources in the collections listed below');
        }
        if (selected_type == 'automated_access_approval') {
            $('.bulk_automated_access_approval_content').removeClass('d-none');
            $('#bulk_edit_type_of_bulk_operation').val('automated_access_approval');
            $('#confirm_msg_pop_bulk').html(' automated access request approvals for resources in the collections listed below');
        }
        if (selected_type == 'bulk_delete') {
            $('.bulk_bulk_delete_content').removeClass('d-none');
            $('#bulk_edit_type_of_bulk_operation').val('bulk_delete');
            $('#confirm_msg_pop_bulk').html(' delete the collections listed below');
        }


    };

    this.re_init_bulk = function () {
        bindEvents();
        var selectize = $('.bulk_operation')[0].selectize;
        if (typeof selectize != 'undefined') {
            update_bulk_edit_view(selectize.getValue());
        }
        selfRBE.set_checkbox_bulk(selfRBE.ids_session);
        $('.bulk-edit-modal').on('shown.bs.modal', function () {
            $('.bulk_operation')[0].selectize.setValue('change_status')
            $('.bulk-edit-submit').attr("disabled", false);
        })
    };

    this.set_checkbox_bulk = function () {
        emptyCount();
        if (selfRBE.ids_session != '' && selfRBE.ids_session.length > 0) {
            $.each(selfRBE.ids_session, function (index, value) {
                if ($(".resources_selections-" + value)) {
                    $(".resources_selections-" + value).prop('checked', true);
                }
            });
            updateCount(selfRBE.ids_session.length);
        }
    }
    ;
    /**
     *
     * @param response
     * @param container
     * @param requestData
     */
    this.handlecallback = function (response, container, requestData) {
        try {
            eval('this.' + requestData.action + '(response,container,requestData)');
        } catch (err) {
            try {
                eval('this.' + response[0].action + '(response,container,requestData)');
            } catch (err) {
                try {
                    eval('this.' + requestData.action + '(response,container,requestData)');
                } catch (err) {
                    console.log(err);
                }
            }
        }
    };

    this.bulk_edit_operation = function (response, container) {
        jsMessages('success', response[0]['message']);
        $('.bulk-edit-review-modal').modal('hide');
        $('#num_of_rec_updated').html(selfRBE.ids_session.length);
        setTimeout(function () {
            location.reload();
        }, 4000);
    };
    const initDataTable = function () {
        let dataTableElement = $('#collection_data_table');
        if (dataTableElement.length > 0) {
            this.dataTableObj = dataTableElement.DataTable({
                searchDelay: 800,
                responsive: true,
                processing: true,
                serverSide: true,
                pageLength: pageLength,
                paging: true,
                bInfo: true,
                destroy: true,
                scrollX: true,
                scrollCollapse: false,
                pagingType: 'simple_numbers',
                'dom': "<'row'<'col-md-6 d-flex'f><'col-md-6'p>>" +
                    "<'row'<'col-md-12'tr>>" +
                    "<'row'<'col-md-6'li><'col-md-6'p>>",
                bLengthChange: true,
                lengthMenu: lengthMenuValues,
                language: {
                    info: 'Showing _START_ - _END_ of _TOTAL_',
                    infoFiltered: '',
                    zeroRecords: 'No Collection found.',
                    lengthMenu: " _MENU_ "
                },
                columnDefs: [
                    {orderable: false, targets: [0, -1]},
                ],
                ajax: $("#collection_data_table").data("url"),
                "initComplete": function() {
                },
                drawCallback: function (settings) {
                    initDeletePopup();
                    bindEvents();
                    if (settings.aoData.length > 0) {
                        $('.export_btn').toggleClass('d-none');
                    }
                }
            });
        }
    };

    const bindEvents = function () {
        document_level_binding_element('.delete-custom-field-button', 'click', function () {
            $('#general_modal_close_cust_success').removeClass('d-none');
            $('#general_modal_close_cust_success').attr('href', $(this).data('url'));
            let appHelper = new App();
            appHelper.show_modal_message('Confirmation', '<strong>Are you sure you want to delete this custom field?</strong>', 'danger');
        });
        
        document_level_binding_element('#collection_is_cloning_collection', 'change', function () {
            if ($(this).prop('checked')) {
                $('#collection_dd_custom').removeClass('d-none');
            } else {
                $('#collection_dd_custom').addClass('d-none');
            }
        });
        removeImageCustom();
        init_tinymce_for_element('.single_row_default_feild .apply_froala_editor');
        if ($('.remove_badge_default_value_collection').length > 0) {
            $('.remove_badge_default_value_collection').on('click', function () {
                $(this).parents('.single_row_default_feild:first').remove();
            });
        }
        if ($('.add_badge_default_value').length > 0) {
            $('.add_badge_default_value').on('click', function () {
                if ($(this).data('type') == 'editor') {
                    var single_row = $('.single_row_default_value_sample_editor:first').clone();
                } else {
                    var single_row = $('.single_row_default_value_sample_field:first').clone();
                }
                $(single_row).find('.elm_val_cust_default_field').val('');
                $(single_row).find('.destroy_element').val($(this).data('col_id'));
                var html = $(single_row).html();
                if ($(this).data('type') == 'editor') {
                    html = html.replace('add_wanted_class', 'apply_froala_editor tinymce');
                }
                $(this).parents('.collection_dynamic_details').append(html);
                $(this).parents('.collection_dynamic_details').find('.single_row_default_feild').show();

                $('.remove_badge_default_value_collection').on('click', function () {
                    $(this).parents('.single_row_default_feild:first').remove();
                });
                init_tinymce_for_element('.single_row_default_feild .apply_froala_editor');
            });
        }
        binding_single_checkbox();
        binding_select_all();
        $('.bulk-edit-submit').unbind('click');
        $('.bulk-edit-submit').on('click', function () {
            selfRBE.app_helper.classAction($(this).data('url'), {action: 'fetch_bulk_edit_resource_list'}, 'HTML', 'GET', '', selfRBE);
        });
        $('.bluk-edit-btn').on('click', function () {
            if (selfRBE.ids_session.length <= 0) {
                jsMessages('danger', 'Please select collections before doing bulk operations.');
            } else {
                $('.bulk-edit-modal').modal();
            }
        });
        $('.bulk_operation').change(function () {
            update_bulk_edit_view($(this).val());
        });
    };
    const binding_single_checkbox = function () {

        $(".resources_selections").unbind('change');
        $(".resources_selections").bind('change', function () {
            selfRBE.app_helper.show_loader();
            var data = {
                action: 'bulk_resource_list',
                type: 'collection_bulk_edit',
                bulk: 0
            };
            var current_id = $(this).data().id.toString();
            if (this.checked) {
                data.status = 'add';
                selfRBE.ids_session.push(current_id);
            } else {
                var index = selfRBE.ids_session.indexOf(current_id);
                if (index > -1) {
                    selfRBE.ids_session.splice(index, 1);
                }
                data.status = 'remove';
            }
            selfRBE.app_helper.classAction($(this).data().url, data, 'JSON', 'GET', '', selfRBE, false);
            $('.select_all_checkbox_resources').prop('checked', false);
        });
    };
    const binding_select_all = function () {
        $('.select_all_checkbox_resources').unbind('click');
        $('.select_all_checkbox_resources').click(function () {
            selfRBE.app_helper.show_loader();
            var all_ids = [];
            if (this.checked) {
                $(".resources_selections").prop('checked', true);
            } else {
                $(".resources_selections").prop('checked', false);
            }

            $('.resources_selections').each(function () {
                var current_id = $(this).data('id').toString();
                if (typeof selfRBE.ids_session == 'undefined' || selfRBE.ids_session.length <= 0) {
                    selfRBE.ids_session = [];
                }
                all_ids.push(current_id);
                if (this.checked) {
                    var index = selfRBE.ids_session.indexOf(current_id);
                    if (index < 0) {
                        selfRBE.ids_session.push(current_id);
                    }
                } else {
                    var index = selfRBE.ids_session.indexOf(current_id);
                    if (index > -1) {
                        selfRBE.ids_session.splice(index, 1);
                    }
                }
            });

            var data = {
                action: 'bulk_resource_list',
                type: 'collection_bulk_edit',
                ids: all_ids,
                bulk: 1
            };

            if (this.checked) {
                data.status = 'add';
            } else {
                data.status = 'remove';
            }
            selfRBE.app_helper.classAction($(this).data().url, data, 'JSON', 'GET', '', selfRBE, false);
        });
    };
    this.bulk_resource_list = function (response, container) {
        emptyCount();
        var ids = response[0]['ids'].split(',');
        if (ids != '' && ids.length > 0) {
            updateCount(ids.length);
        }
        selfRBE.app_helper.hide_loader();
    };
    const emptyCount = function () {
        $('#resource_selected').remove();
        $('#number_of_bulk_selected_popup').html('');
        $('#clear_all_selection').remove();
        $('#select_all_records_span').remove();
    };
    const updateCount = function (number_selected) {
        emptyCount();
        if (number_selected > 0) {
            let text = (number_selected > 1) ? 'collections' : 'collection';
            $('#collection_data_table_filter label').append('<span style="color:#204f92" class="ml-10px font-weight-bold" id="resource_selected">  <strong  class="font-size-16px ">' + number_selected + '</strong> ' + text + ' selected  | </span>  ');
            $('#collection_data_table_filter label').append('<a href="javascript://" id="clear_all_selection">Clear selected</a>');

            $('#number_of_bulk_selected_popup').html('<span style="color:#204f92" class="ml-10px font-weight-bold" id="resource_selected">  ( <strong  class="font-size-16px ">' + number_selected + '</strong> ' + text + ' will be affected ) </span>');
        }
        $('#clear_all_selection').unbind('click');
        $('#clear_all_selection').bind('click', function () {
            var data = {
                action: 'bulk_resource_list_clear_all',
                ids: selfRBE.ids_session,
                bulk: 1,
                status: 'remove'
            };

            selfRBE.ids_session = [];
            updateCount(selfRBE.ids_session.length);

            selfRBE.app_helper.classAction($('.select_all_checkbox_resources').data().url, data, 'JSON', 'GET', '', selfRBE, false);
        });
    };

    this.setTotalRecords = function (total_records) {
        selfRBE.total_records = total_records;
    }

    /**
     *
     * @param response
     * @param container
     * @param requestData
     */
    this.bulk_resource_list_clear_all = function (response, container, requestData) {
        location.reload();
    };
    const initDeletePopup = function () {
        $('.collection_delete').click(function () {
            $('#modalPopupBody').html('Are you sure you want to delete this collection? This will remove all description, resources, files, indexes, and transcripts associated with this Collection from the system. There is no undoing this action.');
            $('#modalPopupTitle').html('Delete "' + $(this).data().name + '" Collection');
            $('#modalPopupFooterYes').attr('href', $(this).data().url);
            $('#modalPopup').modal('show');
        });
    };

    const manageTabs = function () {
        let tabType = window.location.pathname.substr(window.location.pathname.lastIndexOf('/') + 1);
        if (tabType != '') {
            $('#' + tabType + '_tab').click();
        }

        $('#collectionTabs a').click(function () {
            let tabType = window.location.pathname.substr(window.location.pathname.lastIndexOf('/') + 1);
            let currentTab = $(this).data().tab;
            if ($.inArray(tabType, ['general_settings', 'collection_description', 'resource_description', 'index_description']) >= 0)
                window.history.replaceState({}, document.title, window.location.pathname.replace(/\/[^\/]*$/, '/' + currentTab));
            else
                window.history.replaceState({}, document.title, window.location.pathname + '/' + currentTab);

        });
    }

    $(window).on('load', function () {
        $('[data-toggle="tooltip"]').tooltip({ trigger: 'hover' });
    });
}
