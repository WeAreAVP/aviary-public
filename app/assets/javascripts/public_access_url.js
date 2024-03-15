/**
 * keyboard And Transliteration Handler
 *
 * @author Furqan Wasi <furqan@weareavp.com>
 *
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 *
 */

function PublicAccessUrl() {

    let appHelper = new App();
    let that = this;

    this.initialize = function () {

        appHelper.serverSideDatatable('#public_access_urls_table', that, $('#public_access_urls').data('url'));
        document_level_binding_element('#start_time_share, #end_time_share', 'keyup', function () {
            let time = $(this).val();
            let seconds = humanToSeconds(time);
            if (!isNaN(time)) {
                $(this).val(secondsToHuman(time));
            } else if (isNaN(seconds)) {
                $(this).val('00:00:00');
            }
        });

        timePickerShare();
    };

    this.setPeriodTimePeriod = function (start, end, type) {
        let duration = '';
        if (start && end) {
            duration = start + ' - ' + end;
        }

        let data = {
            action: 'encryptedInfo',
            collection_resource_id: $('#url_encryption').data('resoruceid'),
            duration: duration,
            auto_play: $('#auto_play_video').prop('checked'),
            start_time: $('#start_time_share').val(),
            start_time_status: $('.start_time_checkbox').prop('checked'),
            end_time: $('#end_time_share').val(),
            end_time_status: $('.end_time_checkbox').prop('checked'),
            type: type,
        };

        if ($('#public_access_url_id').length > 0 && $('#public_access_url_id').val() != '') {
            data.update_access_url_id = $('#public_access_url_id').val();
        }

        appHelper.classAction($('#url_encryption').data('url'), data, 'JSON', 'GET', '', that, true);
    };

    this.encryptedInfo = function (response, _container, requestData) {
        if (requestData.type == 'ever_green_url')
            $('#ever_green_url').text(response.encrypted_data);
        else {
            $('#public_access_url').text(response.encrypted_data);
        }
        if ($('#public_access_url_id').length > 0 && $('#public_access_url_id').val() != '') {
            location.reload();
        }
    };

    this.datatableInitComplete = function () {
        document_level_binding_element('.public_access_status', 'change', function () {
            that.update_information('updateStatus', $(this).data('id'), $(this).prop('checked'));
        });

        document_level_binding_element('.access-delete', 'click', function () {
            $('#general_modal_close_cust_success').removeClass('d-none');
            $('#general_modal_close_cust_success').attr('href', $('#public_access_urls_table').data('update-info') + '?action_type=delete_access&id=' + $(this).data('id'))
            appHelper.show_modal_message('Are you sure?', 'Are you sure you want to delete this public access?', 'danger');
        });

        document_level_binding_element('.generate-link', 'click', function () {
            let outter = this;
            setTimeout(function () {
                let response = that.geDateRange();
                let startDate = response.startDate;
                let endDate = response.endDate;
                that.setPeriodTimePeriod(startDate, endDate, $(outter).data('type'));
            }, 500);
        });

        that.greenLinkBinding();
        document_level_binding_element('.access-edit', 'click', function () {
            let data = {
                action: 'edit',
                type: $(this).data('type')
            };
            appHelper.classAction($(this).data('url'), data, 'HTML', 'GET', '', that, true);
        });

        $('[data-toggle="tooltip"]').tooltip({ trigger: 'hover' });
        var clipboard = new Clipboard('.copy-public-access-url');
        clipboard.on('success', function (e) {
            jsMessages('success', 'Copied!');
        });
    };

    this.geDateRange = function () {
        let startDate = null;
        let endDate = null;
        if ($('#public_access_time_period').length > 0 && $('#public_access_time_period').data('daterangepicker') != 'undefined') {
            startDate = $('#public_access_time_period').data('daterangepicker').startDate.format('MM-DD-YYYY HH:mm');
            endDate = $('#public_access_time_period').data('daterangepicker').endDate.format('MM-DD-YYYY HH:mm')
        }
        return {startDate: startDate, endDate: endDate}
    };

    this.update_information = function (action_type, id, value) {
        let data = {
            action: 'updateStatus',
            action_type: action_type,
            status: value,
            id: id
        };
        appHelper.classAction($('#public_access_urls_table').data('update-info'), data, 'json', 'GET', '', that, false);
    };

    this.greenLinkBinding = function () {
        document_level_binding_element('.generate-link-green-url', 'click', function () {
            let outter = this;
            $(this).addClass('anchor-disable-custom');
            setTimeout(function () {
                $(outter).removeClass('anchor-disable-custom');
            }, 1500);
            setTimeout(function () {
                appHelper.show_modal_message('Warning', '<strong>If you regenerate this URL, the previous URL will become inactive and all users with that URL will lose access. Would you still like to regenerate?<strong>', 'danger');
                $('#general_modal_close_cust_success').removeClass('d-none');
                $('#general_modal_close_cust_success').attr('data-type', $(outter).data('type'));
                $('#general_modal_close_cust_success').addClass('generate-link-green-url-confirm');
                $('.generate-link-green-url-confirm').unbind('click');
                $('.generate-link-green-url').off('click');
                bindingElement('.generate-link-green-url-confirm', 'click', function () {
                    that.setPeriodTimePeriod(null, null, $(outter).data('type'));
                    $('#general_modal_message_cust').modal('hide');
                }, true);

            }, 500);
        }, true);

    };

    this.edit = function (response) {
        if (response) {
            $('#access_edit_popup .modal-body').html(response);
            $('#access_edit_popup').modal('show');
            dateTimePicker(that, '#public_access_time_period', 'down');
            $('.start_time_checkbox').click(function () {
                if ($(this).prop("checked") === true) {
                    $('.video-start-time').removeAttr('disabled');

                } else {
                    $('.video-start-time').attr('disabled', 'disabled');
                }
            });
        }
    };

    /**
     *
     * @param response
     */
    this.updateStatus = function (response, _container, requestData) {

        if (response['status']) {
            jsMessages('success', response['msg']);
        } else {
            jsMessages('danger', response['msg']);
        }
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
            err;
        }
    };
}
