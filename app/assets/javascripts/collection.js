/**
 * Collection Management
 *
 * @author Nouman Tayyab <nouman@weareavp.com>
 *
 */

function Collection() {
    this.dataTableObj;
    this.initialize = function () {
        initDataTable();
        bindEvents();
        manageTabs();
        init_tinymce_for_element('#collection_about');

        let display_settings = new DisplaySettings();
        display_settings.init_display_settings('collection');
    };
    const initDataTable = function () {
        let dataTableElement = $('#collection_data_table');
        if (dataTableElement.length > 0) {
            this.dataTableObj = dataTableElement.DataTable({
                responsive: true,
                pageLength: 100,
                bInfo: true,
                destroy: true,
                bLengthChange: false,
                scrollX: true,
                scrollCollapse: false,
                pagingType: 'simple_numbers',
                'dom': "<'row'<'col-md-6'f><'col-md-6'p>>" +
                    "<'row'<'col-md-12'tr>>" +
                    "<'row'<'col-md-5'i><'col-md-7'p>>",
                language: {
                    info: 'Showing _START_ - _END_ of _TOTAL_',
                    infoFiltered: '',
                    zeroRecords: 'No Collection found.',
                },
                columnDefs: [
                    {orderable: false, targets: -1}
                ],
                initComplete: function (settings) {
                    initDeletePopup();
                    if (settings.aoData.length > 0) {
                        $('.export_btn').toggleClass('d-none');
                    }
                }
            });
        }
    };

    const bindEvents = function () {

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
            if ($.inArray(tabType, ['general_settings', 'collection_description', 'resource_description']) >= 0)
                window.history.replaceState({}, document.title, window.location.pathname.replace(/\/[^\/]*$/, '/' + currentTab));
            else
                window.history.replaceState({}, document.title, window.location.pathname + '/' + currentTab);

        });
    }
}
