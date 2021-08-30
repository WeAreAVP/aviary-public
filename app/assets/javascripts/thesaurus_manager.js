/**
 * Ohms Manager
 *
 * @author Furqan Wasi <furqan@weareavp.com>
 *
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 */
"use strict";

function ThesaurusManager() {
    let that = this;
    let appHelper = new App();

    this.initializeForm = function () {
        initVocabularyUpload();
    };

    this.initialize = function () {
        initTableListing();
        initDeletePopup();
        initAssignFieldPopup();
        fileListingForThesaurus();
    };

    let fileListingForThesaurus = function () {
        document_level_binding_element('.field_listing_popup', 'click', function () {
            if ($(this).data('listOfFields').replaceAll(',', '<br/>'))
                $('.field_listing_theasurus_info').html($(this).data('listOfFields').replaceAll(',', '<br/>'));
        });

        document_level_binding_element('#assignment_option_custom_thesaurus', 'change', function () {
            if ($(this).val() == 0) {
                $('assign_thesaurus_to_vocab_dropdown').fadeIn('10');
            } else {
                $('assign_thesaurus_to_vocab_dropdown').fadeOut('10');
            }
            $('.assign_thesaurus_to_vocab_dropdown').fadeOut('10');
            let data = {
                js_action: 'field_list',
                action: 'fieldList',
                thesaurus_id: $('#selected_file_t').val(),
                action_type: $(this).val()
            };
            appHelper.classAction($(this).data('url'), data, 'HTML', 'GET', '', that, true);
        });


        document_level_binding_element('#list_of_fields_dropdown', 'change', function () {
            $('.assign_thesaurus_to_vocab_dropdown').fadeIn('600');
            let info = $(this).val().split('||-@||');
            let field = info[0]
            let type_of_field = info[1]
            if (type_of_field == 'dropdown') {
                $('.assign_thesaurus_to_vocab').fadeIn('600');
                $('.assign_thesaurus_to_dropdown').fadeIn('600');
            } else {
                $('.assign_thesaurus_to_vocab').fadeIn('600');
                $('.assign_thesaurus_to_dropdown').fadeOut('600');
            }
        });

    };

    this.auto_complete = function () {
        document_level_binding_element('.thesaurus_term_autocomplete', 'focus', function () {
            let min_length = 0;
            if (!$(this).hasClass('ui-autocomplete-input')) {
                $(this).autocomplete({
                    source: $(this).data('path') + '?tId=' + $(this).data('assigned-thesaurus') + '&typeOfList=' + $(this).data('typeOfList'),
                    minLength: min_length,
                    select: function (event, ui) {
                        $(this).val(ui.item.value);
                    },
                    change: function (e, ui) {
                        if (!(ui.item)) {
                            e.target.value = "";
                        }
                    },
                }).on('focus', function () {
                    if (min_length == 0)
                        $(this).keydown();
                });
            }
            $(this).autocomplete("search");
        });

    };

    this.fieldList = function (response) {
        $('#list_of_fields').html(response);
        $('#list_of_fields_dropdown').selectize();
    };

    let initAssignFieldPopup = function () {
        document_level_binding_element('.assign_thesaurus_to_field', 'click', function () {
            $('#thesaurus_id').text($(this).data('title'));
            $('#selected_file_t').val($(this).data('id'));
        });
    };

    let initTableListing = function () {
        let config = {
            responsive: true,
            processing: true,
            serverSide: true,
            pageLength: pageLength,
            bInfo: true,
            destroy: true,
            bLengthChange: true,
            lengthMenu: lengthMenuValues,
            scrollX: true,
            scrollCollapse: false,
            pagingType: 'simple_numbers',
            'dom': "<'row'<'col-md-6 d-flex'f><'col-md-6'p>>" +
                "<'row'<'col-md-12'tr>>" +
                "<'row'<'col-md-6'li><'col-md-6'p>>",
            language: {
                info: 'Showing _START_ - _END_ of _TOTAL_',
                infoFiltered: '',
                zeroRecords: 'No Records found.',
                lengthMenu: " _MENU_ "
            },
            ajax: {
                url: $('#thesaurus_list_table').data('url'),
                type: 'POST'
            },
            columnDefs: [
                {orderable: false, targets: [-1, -2]}
            ],
            initComplete: function (settings) {
                try {
                    that.datatableInitComplete(settings);
                } catch (e) {

                }
            }
        }

        appHelper.serverSideDatatable('#thesaurus_list_table', that, config, $('#thesaurus_list_table').data('url'))
    };

    this.datatableInitComplete = function (settings) {
    };

    const initDeletePopup = function () {
        document_level_binding_element('.thesauru_delete', 'click', function () {
            $('#modalPopupBody').html('Are you sure you want to delete this thesaurus? There is no undoing this action.');
            $('#modalPopupTitle').html('Delete "' + $(this).data().name + '" Thesaurus');
            $('#modalPopupFooterYes').attr('href', $(this).data().url);
            $('#modalPopup').modal('show');
        });
    };

    let initVocabularyUpload = function () {
        document_level_binding_element('.ohms_integrations_vocabulary', 'change', function () {
            let filename = '';
            let files = $(this).prop('files');
            if (files.length > 0) {
                let file = files[0];
                filename = file.name;
                let fileExt = filename.split('.').pop();

                if ((file.type != '' && file.type != 'text/csv' && file.type != 'application/vnd.ms-excel') || (file.type == '' && fileExt != 'csv')) {
                    filename = '<span class="text-danger">Invalid file type.</span>';
                    $(this).val('');
                    if ($('.operation_type_cust').length > 0) {
                        $('.operation_type_cust').fadeOut(600);
                    }
                } else if ($('.operation_type_cust').length > 0) {
                    $('.operation_type_cust').fadeIn(600);
                }

            } else {
                $('.operation_type_cust').fadeOut(600);
            }
            $(this).parent().next().html(filename);
        });

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
            console.log(err);
        }
    };
};