/**
 * ResourcePageCommon Management
 *
 * @author Furqan Wasi <furqan@weareavp.com>
 *
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 *
 */
function ResourcePageCommon() {


    this.initialize = function (parentElement) {
        dataValidation(parentElement);
        bindingAddRow(parentElement);
        bindingRemoveField(parentElement);
        bindDescriptionModelClose(parentElement);
    };

    let bindingAddRow = function (parentElement) {
        document_level_binding_element(parentElement + ' .addmore-row', 'click', function () {
            if ($(this).data().is_repeatable == false) {
                $(this).hide();
            }
            var new_html = $(this).parents('.current-parent').find('.row_clone').html();
            let identifier = Math.random().toString(36).substring(2, 15);
            if ($(this).data('type') == 'editor') {
                new_html = new_html.replace('add_wanted_class', ' apply_froala_editor tinymce apply_froala_editor_' + identifier);
            }

            let unique_identifier = 'select_option_new_added' + identifier;
            if (new_html.includes("select_option")) {
                new_html = new_html.replaceAll('select_option', ' select_option_new_added ' + unique_identifier);
            }

            $(this).parents('.current-parent').find('.single_row_dynamic_form').append(new_html);
            $('.remove-field').click(function (event) {
                $(this).parents('.current-parent').find('.addmore-row').show();
                $(this).parents('.parent_of_each_row').remove();
            });
            $('.tokenMaker').tagsinput({
                tagClass: 'big'
            });
            $('.bootstrap-tagsinput input').attr('style', 'width: 200px;');

            if ($(this).data('type') == 'editor') {
                init_tinymce_for_element('.apply_froala_editor_' + identifier);
            }
            setTimeout(function () {
                $('.' + unique_identifier).selectize();
            }, 50);
        });
    };

    let dataValidation = function (parentElement) {
        $(parentElement + ' .edit_collection_resource').on('submit', function (e) {
            $(parentElement + ' .form-control.date.value_holder').each(function (index, value) {
                var regExFull = /^\d{4}-\d{2}-\d{2}$/;
                var regExYm = /^\d{4}-\d{2}$/;
                var regExy = /^\d{4}$/;
                value_string = $.trim($(value).val());
                if (!value_string.match(regExFull) && !value_string.match(regExYm) && !value_string.match(regExy)) {
                    jsMessages('danger', 'One ore more date(s) given are invalid. Allowed date formats are ( yyyy-mm-dd or yyyy-mm or yyyy)');
                    e.preventDefault();
                }
            });
        });
    };

    let bindingRemoveField = function (parentElement) {
        document_level_binding_element(parentElement + ' .remove-field', 'click', function () {
            $(this).parents('.current-parent').find('.addmore-row').show();
            $(this).parents('.parent_of_each_row').remove();
        });
    };

    let bindDescriptionModelClose = function (parentElement) {
        document_level_binding_element(parentElement + ' #modal-close', 'click', function () {
            $(parentElement).removeClass('open');
        }, true);
    }

}
