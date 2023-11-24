/**
 * Organization Field Management
 *
 * @author Furqan Wasi <furqan@weareavp.com>
 *
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 *
 */
"use strict";

function OrganizationFieldsManagement() {
    let that = this;
    let appHelper = new App();

    this.initialize = function () {
        binding();
    };

    this.toggleStatusBinding = function () {
        toggleStatus();
        initFieldsSorts();
    }
    this.toggleCollectionEditBinding = function () {
        initFieldsSorts('collection');
    }

    const binding = function () {
        collectionListPopup();
        manageFieldAssignment();
        editCustomFieldInfo();
        initFieldsSorts();
        toggleStatus();
        fetchCollectionList();
        assignField();
        editVocabulary();
        deleteField();
        activeMenuManage();
        editIndexField();
        $("#organization_field_settings_content #manage_fields_options").unstick();
        if ($(window).width() >= 992) {
            $("#organization_field_settings_content #manage_fields_options").sticky({
                topSpacing: 50,
                responsiveWidth: true
            });
        } else {
            $("#organization_field_settings_content #manage_fields_options").sticky({
                topSpacing: 0,
                responsiveWidth: true
            });
        }
        $("#organization_field_settings_content #manage_fields_options").sticky('update');

        if (typeof Cookies.get('activeMenuParent') != 'undefined') {
            $('#' + Cookies.get('activeMenuParent')).click();
            if (typeof Cookies.get('activeMenu') != 'undefined') {
                setTimeout(function () {
                    $('#' + Cookies.get('activeMenu')).click();
                }, 100);
            }
        }


    };
    const collectionListPopup = function () {
        document_level_binding_element('.list_of_collections_action', 'click', function () {
            appHelper.show_modal_message('Available in Collection', $('.list_of_collections').html(), 'info', null);
        });
    };

    const activeMenuManage = function () {
        document_level_binding_element('.field_config_menu', 'click', function () {
            Cookies.set('activeMenu', $(this).attr('id'));
        });
        document_level_binding_element('.parent_menu', 'click', function () {
            Cookies.set('activeMenuParent', $(this).attr('id'));
        });
    }
    const deleteField = function () {
        document_level_binding_element('.delete_field', 'click', function () {
            $('#general_modal_close_cust_success').attr('href', $(this).data('url'));
            $('#general_modal_close_cust_success').removeClass('d-none');
            appHelper.show_modal_message('Confirmation', '<strong>Are you sure you want to remove this field from this organization?</strong><br/><br/>' +
                '\'<p class=" text-muted">Note: Removing this field will remove its availability from your organization. If any resources/collection in this organization uses this field currently, then any existing metadata for this field will be deleted from the resources of current organization. This will not affect resources in other collections that use this field currently.</p>\'', 'danger', null);
        });
    };

    const editVocabulary = function () {
        document_level_binding_element('.edit_vocabulary', 'click', function () {
            $('#update_vocabulary_popup .modal-title').html(' Manage "' + $('#custom_fields_label').val() + '" vocabulary')
            $('#new_vocabulary').val($('#custom_fields_vocabulary').val());
            $('.modal').modal('hide');
        });

        document_level_binding_element('#reset_to_default', 'click', function () {
            let data = {
                js_action: 'editVocabulary',
                action: 'editVocabulary',
                field: $('.edit_vocabulary').data('field'),
                type: 'resource_fields',
                update_type: 'reset_to_default',
            };
            updateVocabulary($('#update_vocabulary_btn').data('url'), data);
        });

        document_level_binding_element('#update_vocabulary_btn', 'click', function () {
            let data = {
                js_action: 'editVocabulary',
                action: 'editVocabulary',
                field: $('.edit_vocabulary').data('field'),
                type: $('.edit_vocabulary').data('fieldType') || 'resource_fields',
                update_type: $('#update_vocabulary').val(),
                vocabulary: $('#new_vocabulary').val(),
                list_type: 'vocabulary'
            };
            updateVocabulary($(this).data('url'), data);
        });

        document_level_binding_element('#update_dropdown_options_btn', 'click', function () {
            let data = {
                js_action: 'editVocabulary',
                action: 'editVocabulary',
                field: $('.edit_dropdown_option').data('field'),
                type: 'resource_fields',
                update_type: $('#update_dropdown_options').val(),
                vocabulary: $('#new_update_dropdown_options').val(),
                list_type: 'dropdown_options'
            };
            updateVocabulary($(this).data('url'), data);
        });

        document_level_binding_element('.edit_dropdown_option', 'click', function () {
            $('#update_dropdown_option_popup .modal-title').html(' Manage "' + $('#custom_fields_label').val() + '" Dropdown Options')
            $('#new_update_dropdown_options').val($('#custom_fields_dropdown_options').val());
            $('.modal').modal('hide');
        });
    };
    const updateVocabulary = function (url, data) {
        appHelper.classAction(url, data, 'JSON', 'POST', '', that, true);
    }
    this.editVocabulary = function () {
        that.addFieldToSelectCollection();
    };

    const manageFieldAssignment = function () {
        document_level_binding_element('.manage_field_assignment', 'click', function () {
            let assignment_option_custom = $('#assignment_option_custom').selectize({placeholder: 'Select Option'});
            assignment_option_custom[0].selectize.setValue('');
            $('#list_of_collections').html('');
            $('#selected_file').val($(this).data('field'));
            $('#assignment_field_popup .modal-title').html('Assign "' + $(this).data('label') + '" to Collections');
            $('#assignment_field_popup').modal();
        });
    };

    const editCustomFieldInfo = function () {
        document_level_binding_element('.edit_custom_field_info, .edit-custom-field-button', 'click', function () {
            $('#custom_fields_form').trigger("reset");
            let data = {action: 'fieldValueInformation', field_type: $(this).data('fieldtype')};
            $('.edit_vocabulary').data('field', $(this).data('field'));
            appHelper.classAction($(this).data('url'), data, 'JSON', 'GET', '', that, true);
        });
    };

    this.fieldValueInformation = function (response) {
        if (typeof response != 'undefined' && response.responseText) {
            $('#custom_fields_popup').html(response.responseText);
            $('#collection_custom_fields').modal('show');
            $('#custom_fields_field_type').selectize();
            document_level_binding_element('.meta-type-select.field_type_manager.selectized', 'change', function () {
                if ($(this).val() === 'dropdown') {
                    $('.meta-options-div').show();
                    return $('.meta-custom-options').prop('required', true);
                } else {
                    $('.meta-custom-options').val('');
                    $('.meta-options-div').hide();
                    return $('.meta-custom-options').prop('required', false);
                }
            }, true);
        }
    };

    const initFieldsSorts = function (from) {
        $('#sort_facet_fields_table tbody').sortable({
            axis: "y",
            containment: "parent",
            cursor: "move",
            items: "tr:not([data-is-required-field='true'])",
            tolerance: "pointer",
            update: function () {
                updateSortInfo(this)
            }
        });
    };


    const toggleStatus = function () {
        $('.template-data-field-is-facetable').on('change', function () {
            updateSortInfo($($(this).parents('tbody')));
        });
    };

    const fetchCollectionList = function () {

        document_level_binding_element('#assignment_option_custom', 'change', function () {
            let data = {
                js_action: 'collection_list',
                action: 'collectionList',
                field: $('#selected_file').val(),
                action_type: $(this).val()
            };
            appHelper.classAction($(this).data('url'), data, 'HTML', 'GET', '', that, true);
        });

    };

    this.collectionList = function (response) {
        $('#list_of_collections').html(response);
        $('#collection_ids_assignment').selectize();
    };

    const assignField = function () {
        document_level_binding_element('#assign_field', 'click', function () {
            let data = {
                js_action: 'assignField',
                action: 'assignField',
                collection_ids: $('#collection_ids_assignment').val(),
                field: $('#selected_file').val(),
                action_type: $('#assignment_option_custom').val()
            };
            appHelper.classAction($('#assignment_option_custom').data('url'), data, 'JSON', 'GET', '', that, true);
        });
    };

    this.assignField = function () {
        that.addFieldToSelectCollection();
        jsMessages('success', 'Information updated successfully.');
    };

    //################# Organization Fields End management #################

    //################# Collection Fields Start management #################
    this.initializeCollection = function () {
        bindingCollection();
    };

    const bindingCollection = function () {
        initFieldsSortsCollection();
        addFieldToSelectCollection();
        assignCollectionFields();
        statusTombToggle();
        initIndexFieldsSortsCollection();
        statusDisplayToggle();
    };

    const assignCollectionFields = function () {
        document_level_binding_element('.assign-field-to-collection', 'click', function () {
            $('#general_modal_message_cust .modal-dialog').removeClass('modal-md');
            $('#general_modal_message_cust .modal-dialog').addClass('modal-xl');
            $('#general_modal_message_cust #general_modal_close_cust_success').html('Add Field to list');
            $('#general_modal_message_cust #general_modal_close_cust_success').addClass('add_field_to_select_collection');
            $('#general_modal_message_cust #general_modal_close_cust_success').removeClass('d-none');
            $('.general_modal_body_cust select').selectize();
            $('#general_modal_message_cust #general_modal_title_cust').html('Manage "' + $(this).data('label') + '\'s" Assignment to Collection(s)');
            let html = "<div class=\"row\">" +
                "          <div class=\"col-12\">\n" +
                "            <label> Select Field</label>";
            html += $('#collection_dropdown').html().replace('custom_drop_down_class', 'collection_for_fields');
            html = html.replace('custom_drop_down_class', 'collection_for_fields')
            html += "          </div>\n" +
                "           </div>\n"
            $('#general_modal_message_cust .general_modal_body_cust').html(html);
            $('#general_modal_message_cust #general_modal_title_cust').html(' Assign field to "' + $('#collection_title').val() + '"');
            $('#collection_for_fields').selectize();
            $('#general_modal_message_cust').modal();
        });
    };

    const statusTombToggle = function () {

        document_level_binding_element('.template-data-field-tomb, .template-data-field-visible', 'click', function () {
            if ($(this).hasClass('template-data-field-tomb') && $('.template-data-field-tomb:checked').length > 3) {
                console.log('asdas');
                $(this).prop('checked', false);
                return alert('Cannot select more then 3 tombstone values');
            }

            // todo: woke on this to mage preview field work
            updateSortInfoCollection($('#collection_resource_field_preview_org'));

        });
    };

    const statusDisplayToggle = function () {
        document_level_binding_element('.display.toggle-switch__input', 'click', function () {
            updateIndexFieldInfoCollection($('#collection_index_field_preview_org'));
        });
    };

    const initIndexFieldsSortsCollection = function () {
        $('#collection_index_field_preview_org').sortable({
            axis: "y",
            containment: "parent",
            cursor: "move",
            items: "tr:not([data-is-required-field='true'])",
            tolerance: "pointer",
            update: function () {
                updateIndexFieldInfoCollection(this)
            }
        });
    };

    /**
     *
     * @param obj
     */
    const updateIndexFieldInfoCollection = function (obj) {
        let info = {};

        $('#' + $(obj).attr('id') + ' tr').each(function (index, objectTr) {
            info[index] = {system_name: $(this).data('field')};
            info[index][$(obj).data('orderCustom')] = index;
            if (typeof $(obj).data('statusColumns') != 'undefined' && $(obj).data('statusColumns').length > 0) {
                $.each($(obj).data('statusColumns').split(','), function (_index, value) {
                    info[index][value] = $(objectTr).find('.' + value).prop('checked');
                });
            }
            if (typeof $(obj).data('internalOnlyColumns') != 'undefined' && $(obj).data('internalOnlyColumns').length > 0) {
                $.each($(obj).data('internalOnlyColumns').split(','), function (_index, value) {
                    info[index][value] = $(objectTr).find('.' + value).prop('checked');
                });
            }
        });

        let data = {
            js_action: 'updateSortCollectionIndexFields',
            action: 'updateSortCollectionIndexFields',
            info: info,
            options: $(obj).data('option'),
            type: $(obj).data('type')
        };
        let appHelper = new App();
        appHelper.classAction($('#sort_custom_fields_table').data('url'), data, 'JSON', 'POST', '', that, true);
    };

    const initFieldsSortsCollection = function () {
        $('#collection_resource_field_preview_org').sortable({
            axis: "y",
            containment: "parent",
            cursor: "move",
            items: "tr",
            tolerance: "pointer",
            update: function () {
                updateSortInfoCollection(this)
            }
        });
    };

    /**
     *
     * @param obj
     */
    const updateSortInfoCollection = function (obj) {
        let info = {};

        $('#' + $(obj).attr('id') + ' tr').each(function (index, objectTr) {
            console.log($(this).data());
            info[index] = {system_name: $(this).data('field')};
            info[index][$(obj).data('orderCustom')] = index;

            if ($(obj).data('statusColumns').length > 0) {
                $.each($(obj).data('statusColumns').split(','), function (_index, value) {
                    info[index][value] = $(objectTr).find('.' + value).prop('checked');
                });
            }
        });

        let data = {
            js_action: 'updateSortCollection',
            action: 'updateSortCollection',
            info: info,
            options: $(obj).data('option'),
            type: $(obj).data('type')
        };
        let appHelper = new App();
        appHelper.classAction($('#sort_custom_fields_table').data('url'), data, 'JSON', 'POST', '', that, true);
    };


    this.updateSortCollection = function () {
        // that.addFieldToSelectCollection();
    };

    this.updateSort = function () {
        jsMessages('success', 'Information updated successfully.');
    };

    /**
     *
     * @param obj
     */
    const updateSortInfo = function (obj) {
        let info = {};
        $('#' + $(obj).attr('id') + ' tr').each(function (index, objectTr) {

            info[index] = {system_name: $(this).data('field')};
            info[index][$(obj).data('orderCustom')] = index;
            if (typeof $(obj).data('statusColumns') != 'undefined' && $(obj).data('statusColumns').length > 0) {
                $.each($(obj).data('statusColumns').split(','), function (_index, value) {
                    info[index][value] = $(objectTr).find('.' + value).prop('checked');
                });
            }
            if (typeof $(obj).data('internalOnlyColumns') != 'undefined' && $(obj).data('internalOnlyColumns').length > 0) {
                $.each($(obj).data('internalOnlyColumns').split(','), function (_index, value) {
                    info[index][value] = $(objectTr).find('.' + value).prop('checked');
                });
            }
        });
        console.log(obj);
        let data = {
            action: 'updateSort',
            js_action: 'updateSort',
            info: info,
            options: $(obj).data('option'),
            type: $(obj).data('type')
        };
        appHelper.classAction($('.sort_update_fields').data('url'), data, 'JSON', 'POST', '', that, true);
    };

    const addFieldToSelectCollection = function () {
        document_level_binding_element('.add_field_to_select_collection', 'click', function () {
            let data = {
                action: 'addFieldToSelectCollection',
                js_action: 'addFieldToSelectCollection',
                field: $('#collection_for_fields').val(),
                collection_ids: []
            };
            appHelper.classAction($('.sort_update_fields').data('url'), data, 'JSON', 'POST', '', that, true);
        });
    };

    const editIndexField = function () {
        document_level_binding_element('.edit-index-field', 'click', function () {
            $('#index-field-edit-form').trigger("reset");
            let data = {action: 'IndexFieldEdit', field_name: $(this).data('name')};
            $('.edit_vocabulary').data('field', $(this).data('field'));
            appHelper.classAction($(this).data('url'), data, 'JSON', 'GET', '', that, true);
        });
    };

    this.IndexFieldEdit = function (response) {
        if (typeof response != 'undefined' && response.responseText) {
            $('#custom_fields_popup').html(response.responseText);
            $('#index_fields_edit').modal('show');
        }
    };

    this.addFieldToSelectCollection = function () {
        that.updateSort();
        setTimeout(function () {
            location.reload();
        }, 2000);
    };

    /**
     *
     * @param response
     * @param container
     * @param requestData
     */
    this.handlecallback = function (response, container, requestData) {
        try {
            eval('this.' + requestData.action + '(response, container, requestData)');
        } catch (err) {
            console.log(err);
        }
    };
}
