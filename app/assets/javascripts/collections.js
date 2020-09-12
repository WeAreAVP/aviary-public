jQuery(function () {
    var fixHelperModified, handle, preview_data, set_switch_fields, updateIndex, updateIndex1;
    $(document).on('submit', '.new_collection_resource_field,.edit_collection_resource_field', function (e) {
        e.preventDefault();
        return $.ajax({
            type: 'POST',
            url: $("#custom_fields_form").attr('action'),
            data: $("#custom_fields_form").serialize(),
            beforeSend: function () {
            },
            error: function (xhr, ajaxOptions, thrownError) {
                var er;
                er = JSON.parse(xhr.responseText);
                return console.log(er);
            },
            success: function (data) {
                return window.location.reload();
            }
        });
    });
    handle = function (e, t) {
        return handle = '.handle';
    };
    fixHelperModified = function (e, tr) {
        var $helper, $originals;
        $originals = tr.children();
        $helper = tr.clone();
        $helper.children().each(function (index) {
            return $(this).width($originals.eq(index).width());
        });
        return $helper;
    };
    updateIndex1 = function (e, ui) {
        var field_values, values;
        $('td.index', ui.item.parent()).each(function (i) {
            return $(this).html(i + 1);
        });
        field_values = {};
        values = {};
        return $('.sort-order-field').each(function (i) {
            return $(this).val(i + 1);
        });
    };
    $(document).on('mouseup', '.collection-metadata-sorting', function (e) {
        return setTimeout((function () {
            $('#sort_collection_default_fields tbody').sortable('destroy');
            return $('#sort_collection_default_fields tbody').unbind();
        }), 300);
    });
    $('.collection-metadata-sorting').on('mousedown', function () {
        return $('#sort_collection_default_fields tbody').sortable({
            handle: '.handle',
            helper: fixHelperModified,
            stop: updateIndex1
        }).disableSelection();
    });
    updateIndex = function (e, ui) {
        var a, data_hash, sort_hash;
        sort_hash = {};
        data_hash = {};
        a = 0;
        $('td.index', ui.item.parent()).each(function (i) {
            return $(this).html(i + 1);
        });
        $('.sort-order-field').each(function (i) {
            var field_name;
            field_name = $('#' + $(this).attr('id')).data('field-name');
            if (field_name !== void 0) {
                a = a + 1;
                data_hash[field_name] = a;
                return $(this).val(a);
            }
        });
        sort_hash['sort_data'] = data_hash;
        return set_switch_fields(sort_hash, null);
    };
    $('#sort_custom_fields_table tbody').sortable({
        handle: handle({
            helper: fixHelperModified
        }),
        stop: updateIndex
    }).disableSelection();
    $(document).on('click', '.save-custom-vocabulary-form', function (e) {
        e.preventDefault();
        return $.ajax({
            type: 'POST',
            url: $(this).attr('href'),
            data: $("#custom_vocabulary_form").serialize(),
            beforeSend: function () {
            },
            error: function (xhr, ajaxOptions, thrownError) {
                var er;
                er = JSON.parse(xhr.responseText);
                return console.log(er);
            },
            success: function (data) {
                if (data.status === "success") {
                    return $('#custom_vocabulary_modal').modal('hide');
                }
            }
        });
    });
    $(document).on('click', '.mapping_structure_table_fetch_data', function (e) {
        e.preventDefault();
        return $.ajax({
            type: 'GET',
            url: $(this).attr("href"),
            beforeSend: function () {
                return $(".mapping_structure_table_loader").show();
            },
            error: function (xhr, ajaxOptions, thrownError) {
                var er;
                er = JSON.parse(xhr.responseText);
                return console.log(er);
            },
            success: function (data) {
                $(".mapping_structure_table_data").html(data);
                return $(".mapping_structure_table_loader").hide();
            }
        });
    });
    $('.template-custom-fields-visibility').on('change', function (e) {
        return $.ajax({
            type: 'POST',
            url: $(this).data("path"),
            data: {
                is_visible: $(this).is(":checked"),
                collection_meta_id: $(this).data("id")
            },
            beforeSend: function () {
            },
            error: function (xhr, ajaxOptions, thrownError) {
                var er;
                er = JSON.parse(xhr.responseText);
                return console.log(er);
            }
        });
    });
    document_level_binding_element('#custom_fields_field_label', 'keyup', function () {
        if ($(this).val().length > 31) {
            jsMessages('danger', 'Field name cannot be greater then 32 characters.')
        }
    }, true);
    $(document).on('click', '.edit-custom-field-button', function (e) {
        e.preventDefault();
        return $.ajax({
            type: 'GET',
            url: $(this).attr('href'),
            data: {
                collection_meta_id: $(this).data("id"),
                methodtype: $(this).data("method-type")
            },
            beforeSend: function () {
            },
            error: function (xhr, ajaxOptions, thrownError) {
                var er;
                er = JSON.parse(xhr.responseText);
                return console.log(er);
            },
            success: function (data) {
                $('#custom_fields_popup').html(data);
                $('#collection_custom_fields').modal('show');
                return $(document).on('change', '#custom_fields_field_column_type', function (e) {
                    if ($(this).val() === '1') {
                        $('.meta-options-div').show();
                        return $('.meta-custom-options').prop('required', true);
                    } else {
                        $('.meta-custom-options').val('');
                        $('.meta-options-div').hide();
                        return $('.meta-custom-options').prop('required', false);
                    }
                });
            }
        });
    });
    $(document).on('change', '.template-data-field', function (e) {
        if ($('.template-data-field-tomb:checked').length > 3) {
            $(this).prop('checked', false);
            return alert('Cannot select more then 3 tombstone values');
        } else {
            return set_switch_fields(null, null);
        }
    });
    $('#resource_description_tab').on('click', function (e) {
        return set_switch_fields(null, null);
    });
    set_switch_fields = function (sort_hash, new_custom) {
        var tombstone_fields, values, visible_fields;
        visible_fields = [];
        tombstone_fields = [];
        values = {};
        $('.template-data-field-tomb:checked').each(function (i) {
            return tombstone_fields.push($(this).data('field-name'));
        });
        $('.template-data-field-visible:checked').each(function (i) {
            return visible_fields.push($(this).data('field-name'));
        });
        values['visible'] = visible_fields;
        values['tombstone'] = tombstone_fields;
        values['collection_title'] = $(".collection-title-field").val();
        values['sort_order'] = sort_hash;
        values['new_custom_value'] = new_custom;
        return preview_data(values);
    };
    preview_data = function (values) {
        values['previous_hash'] = $('.collection-preview-container').data('preview-hash');
        return $.ajax({
            type: 'POST',
            url: $('#resource_description_tab').data("path"),
            data: values,
            success: function (data, textStatus, jqXHR) {
                return $('.collection_resource_preview').html(data);
            },
            beforeSend: function () {
            },
            error: function (xhr, ajaxOptions, thrownError) {
                var er;
                er = JSON.parse(xhr.responseText);
                return console.log(er);
            }
        });
    };
    $(document).on('click', '.update-collection-forms-btn', function (e) {
        var data_hash, insert_hash;
        e.preventDefault();
        insert_hash = {};
        data_hash = {};
        $('#sort_custom_fields_table tr').each(function (i) {
            var id, sort_val, tomb_val, visi_val;
            tomb_val = $(this).find("#is_tombstone").is(":checked");
            visi_val = $(this).find("#is_visible").is(":checked");
            sort_val = $(this).find(".sort-order-field").val();
            id = $(this).find("#is_visible").data("field-id");
            return insert_hash[i] = {
                'is_visible': visi_val,
                'is_tombstone': tomb_val,
                'field_id': id
            };
        });
        data_hash["collection_resource_field"] = insert_hash;
        return $.ajax({
            type: 'POST',
            url: $("#sort_custom_fields_table").data('path'),
            data: data_hash,
            beforeSend: function () {
            },
            error: function (xhr, ajaxOptions, thrownError) {
                var er;
                er = JSON.parse(xhr.responseText);
                return console.log(er);
            },
            success: function (data) {
                var val;
                if (data.status === "success") {
                     return $('.collection-edit-form').submit();
                }
            }
        });
    });
    window.get_data = function (path, _obj) {
        return $.ajax({
            type: 'GET',
            url: path,
            success: function (data, textStatus, jqXHR) {
                $('.loader').hide();
                $('#' + _obj).html(data.partial);
                return set_carousel();
            },
            beforeSend: function () {
                return jsloader('#' + _obj);
            },
            error: function (xhr, ajaxOptions, thrownError) {
                var er;
                er = JSON.parse(xhr.responseText);
                return console.log(er);
            }
        });
    };
    $('.colloction-show-view').children().each(function (index) {
        var id, path;
        id = $(this).attr('id');
        path = $(this).data('path');
        return get_data(path, id);
    });
    return $(document).on('click', '.close-import-popup', function (e) {
        $('.import-csv-file-section').show();
        $('.import-file-confirmation').hide();
        $('#import_csv_btn').text('Import');
        return $('.close-import-popup').attr('data-dismiss', 'modal').text('Close');
    });
});

// ---
// generated by coffee-script 1.9.2