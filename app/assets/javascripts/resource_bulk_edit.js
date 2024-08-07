/**
 * Search Page operations
 *
 * @author Furqan Wasi<furqan@weareavp.com, furqan.wasi66@gmail.com>
 *
 * SearchPage Handler
 *
 * @returns {SearchPage}
 *
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 */

var selfRBE;

function ResourceBulkEdit(ids_session_raw) {
    selfRBE = this;
    selfRBE.app_helper = {};
    selfRBE.ids_session_raw = ids_session_raw;

    /**
     *
     * @returns {none}
     */
    this.initialize = function () {
        selfRBE.app_helper = new App();

        if (typeof selfRBE.ids_session == 'undefined' || selfRBE.ids_session.length <= 0) {
            selfRBE.ids_session = [];
        }

        if (selfRBE.ids_session_raw) {
            selfRBE.ids_session = selfRBE.ids_session_raw.replace(/&quot;/g, '"');
            selfRBE.ids_session = JSON.parse(selfRBE.ids_session);
        }
        selfRBE.re_init_bulk();
    };

    this.re_init_bulk = function () {
        bindings();
        var selectize = $('.bulk_operation')[0].selectize;
        if (typeof selectize != 'undefined') {
            update_bulk_edit_view(selectize.getValue());
        }
        selfRBE.set_checkbox_bulk(selfRBE.ids_session);
    };

    /**
     *
     * @param response
     * @param container
     * @param requestData
     */
    this.bulk_resource_list_clear_all = function (response, container, requestData) {
        location.reload();
    };

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


    /**
     * Bind all elements
     *
     * @returns {undefined}
     */
    const bindings = function () {
        $('.bulk-edit-submit').unbind('click');
        $('.bulk-edit-submit').on('click', function () {
            selfRBE.app_helper.classAction($(this).data('url'), {action: 'fetch_bulk_edit_resource_list'}, 'HTML', 'GET', '', selfRBE);
        });
        bulk_form_submit();
        bulk_option_selection();
        binding_single_checkbox();
        binding_select_all();
        binging_select_all_records();
        $('.bluk-edit-btn').on('click', function () {
            if (selfRBE.ids_session.length <= 0) {
                jsMessages('danger', 'Please select resources before doing bulk operations.');
            } else {
                $('.bulk-edit-modal').modal();
            }
        });
    };

    this.fetch_bulk_edit_resource_list = function (response) {
        $('.bulk-edit-review-content').html(response);
        $('.review_resources').DataTable({
            pageLength: 10,
            bLengthChange: false,
            destroy: true,
            bInfo: true,
        });
    };

    /**
     * Bulk Form Submit
     */
    const bulk_form_submit = function () {
        $('#bulk_edit_form').unbind('submit');
        $('#bulk_edit_form').on('submit', function (e) {
            var form_data = $(this).serialize();

            $('.loadingtextCus').html('<strong class="font-size-21px">Please do not close this window; it will disturb the process.<br/>This process may take a little longer to complete. <br/> <span id="num_of_rec_updated">0</span> record(s) processed out of  ' + selfRBE.ids_session.length + '</strong>');
            selfRBE.app_helper.show_loader_text();
            setTimeout(function () {
                get_progress_status();
            }, 5000);
            selfRBE.app_helper.classAction($('#bulk_edit_form').attr('action'), form_data, 'JSON', 'POST', '', selfRBE);
            e.preventDefault();
        });
    };

    const get_progress_status = function () {
        selfRBE.app_helper.classAction($('#url_form_progress').data('url'), {
            action: 'update_progress',
            bulk_edit_status: $('#bulk_edit_status').val(),
            bulk_edit_type_of_bulk_operation: $('#bulk_edit_type_of_bulk_operation').val(),
            bulk_edit_featured: $('#bulk_edit_featured').val(),
            bulk_edit_collections: $('#bulk_edit_collections').val(),
            ids: selfRBE.ids_session
        }, 'JSON', 'GET', '', selfRBE, false);
    };

    const bulk_option_selection = function () {
            $('.bulk_operation').change(function () {
                update_bulk_edit_view($(this).val());
            });
        }
    ;

    const update_bulk_edit_view = function (selected_type) {
        $('.operation_content').addClass('d-none');
        if (selected_type == 'bulk_delete') {
            $('.bulk_delete_content').removeClass('d-none');
            $('#bulk_edit_type_of_bulk_operation').val('bulk_delete');
            $('#confirm_msg_pop_bulk').html(' delete the resources listed below');
        } else if (selected_type == 'change_status') {
            $('.change_status_content').removeClass('d-none');
            $('#bulk_edit_type_of_bulk_operation').val('change_status');
            $('#confirm_msg_pop_bulk').html(' change the access status of the resources listed below');

        } else if (selected_type == 'change_featured') {
            $('.change_featured_content').removeClass('d-none');
            $('#bulk_edit_type_of_bulk_operation').val('change_featured');
            $('#confirm_msg_pop_bulk').html(' change the featured status of the resources listed below');

        } else if (selected_type == 'assign_to_collection') {
            $('.assign_to_collection_content').removeClass('d-none');
            $('#bulk_edit_type_of_bulk_operation').val('assign_to_collection');
            $('#confirm_msg_pop_bulk').html(' assign the resources listed below to a new collection');

        } else if (selected_type == 'assign_to_playlist') {
            $('.assign_to_playlist_content').removeClass('d-none');
            $('#bulk_edit_type_of_bulk_operation').val('assign_to_playlist_content');
            $('#confirm_msg_pop_bulk').html(' assign the resources listed below to a new playlist');

        } else if (selected_type == 'change_media_file_status') {
            $('.change_child_status_content').removeClass('d-none');
            $('#bulk_edit_type_of_bulk_operation').val('change_media_file_status');
            $('#confirm_msg_pop_bulk').html(' change the access of media file of the resources listed below');
            $('#typeofchildaction').html('media files');
        } else if (selected_type == 'change_resource_index_status') {
            $('.change_child_status_content').removeClass('d-none');
            $('#bulk_edit_type_of_bulk_operation').val('change_resource_index_status');
            $('#confirm_msg_pop_bulk').html(' change the access status of indexes of the resources listed below');
            $('#typeofchildaction').html('indexes');
        } else if (selected_type == 'change_resource_transcript_status') {
            $('.change_child_status_content').removeClass('d-none');
            $('#bulk_edit_type_of_bulk_operation').val('change_resource_transcript_status');
            $('#confirm_msg_pop_bulk').html(' change the access status of transcripts of  the resources listed below');
            $('#typeofchildaction').html('transcripts');
        }
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
                    if (index <= 0) {
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

    const binging_select_all_records = function () {
        $('#select_all_records').unbind('click');
        document_level_binding_element('#select_all_records', 'click',function () {
            selfRBE.app_helper.show_loader();
            $(".resources_selections").prop('checked', false);
            $(".select_all_checkbox_resources").prop('checked', false);
            const searchval = $('#collection_resource_datatable_filter label input').val()
            var data = {
                action: 'bulk_resource_list',
                ids: 'all',
                bulk: 1,
                searchValue: searchval
            };

            data.status = 'add';
            const res = selfRBE.app_helper.classAction($(this).data().url, data, 'JSON', 'GET', '', selfRBE, false);
            res.then((response) => {
                if(response[0]?.is_selected_all == true) {
                    updateCount(selfRBE.total_records)
                    var ids = response[0]['ids'].split(',');
                    if (ids != '' && ids.length > 0) {
                        ids.forEach((id) => {
                            var index = selfRBE.ids_session.indexOf(id);
                            if($(".resources_selections-"+id).prop('checked') == false){
                                $(".resources_selections-"+id).prop('checked', true);
                            }
                            if (index < 0) {
                                selfRBE.ids_session.push(id);
                            }
                        })
                    }
                }
            })
        })
    }

    const binding_single_checkbox = function () {

        $(".resources_selections").unbind('change');
        $(".resources_selections").bind('change', function () {
            selfRBE.app_helper.show_loader();
            var data = {
                action: 'bulk_resource_list',
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

    this.bulk_resource_list = function (response, container) {
        emptyCount();
        var ids = response[0]['ids'].split(',');
        if (ids != '' && ids.length > 0) {
            updateCount(ids.length);
        }
        selfRBE.app_helper.hide_loader();
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

    const updateCount = function (number_selected) {
        emptyCount();
        if (number_selected > 0) {
            $('#collection_resource_datatable_filter label').append('<span style="color:#f05c1f" class="ml-10px font-weight-bold" id="resource_selected">  ( <strong  class="font-size-16px ">' + number_selected + '</strong> resource selected ) </span>  ');
            $('#collection_resource_datatable_filter label').append('<a href="javascript://" id="clear_all_selection">Clear selected</a>');
            $('#collection_resource_datatable_filter label').append('<span style="color:#204f92" class="ml-10px font-weight-bold" id="select_all_records_span">| <a href="javascript://" class="font-weight-bold" id="select_all_records" data-url="/collections/bulk_resource_list">Select All (' + selfRBE.total_records +' records)</a> </span>');
            $('#number_of_bulk_selected_popup').html('<span style="color:#f05c1f" class="ml-10px font-weight-bold" id="resource_selected">  ( <strong  class="font-size-16px ">' + number_selected + '</strong> resource(s) will be affected ) </span>');
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

    this.update_progress = function (response) {
        $('#num_of_rec_updated').html(response[0].count);
        setTimeout(function () {
            get_progress_status();
        }, 5000);
    };

    this.actionBasedMethodExc = function (response, container, caller, requestData) {
        selfRBE.app_helper.actionBasedMethodExc(response, container, caller, requestData);
    };

    const emptyCount = function () {
        $('#resource_selected').remove();
        $('#number_of_bulk_selected_popup').html('');
        $('#clear_all_selection').remove();
        $('#select_all_records_span').remove();
    };

    this.setTotalRecords = function (total_records) {
        selfRBE.total_records = total_records;
    }
}
