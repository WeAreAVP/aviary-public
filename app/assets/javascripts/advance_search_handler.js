/**
 * Advance Search Handler Page operations
 *
 * @author Furqan Wasi<furqan@weareavp.com, furqan.wasi66@gmail.com>
 *
 * Advance Search Handler
 *
 * @returns {AdvanceSearchHandler}
 *
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 */

function AdvanceSearchHandler() {
    var selfAdvanceSearchHandler;
    /**
     * Initialize Advance Search
     *
     * @param filter_terms JSON
     *
     * @returns {none}
     */
    selfAdvanceSearchHandler = this;
    this.initialize = function (filter_terms, search_type) {
        selfAdvanceSearchHandler.search_type = 'simple';
        selfAdvanceSearchHandler.search_type = search_type;
        filter_terms = filter_terms;
        setTimeout(function () {
            $('.cloneable_search .type_of_field_selector.selectized')[0].selectize.destroy();
            $('.cloneable_search .type_of_search.selectized')[0].selectize.destroy();
            $('.cloneable_search .op_selector.selectized')[0].selectize.destroy();
            if (search_type == 'simple') {
                let type_of_field_selector = $('.type_of_field_selector_single');
                let type_of_field_selector_selectize = type_of_field_selector[0].selectize;
                if (filter_terms[0] && filter_terms[0].field && type_of_field_selector_selectize) {
                    type_of_field_selector_selectize.setValue(filter_terms[0].field);
                }
            }
        }, 50);

        setTimeout(function () {

            $.each(filter_terms, function (index, single_filter) {
                if (single_filter && single_filter.search_query && single_filter.field) {
                    var allow_remove = true;
                    var allow_operator = true;
                    if (index == 0) {
                        allow_remove = false;
                        allow_operator = false;
                    }
                    let identifier = add_new_term_line(allow_remove, allow_operator, false);
                    setTimeout(function () {
                        set_term_field_values(single_filter, identifier);
                    }, 50);
                }
            });

            if ($('.line.actual').length <= 0) {
                add_new_term_line(false, false);
            }
        }, 100);
        bindings();
    };

    /**
     * Bind all elements
     *
     * @returns {undefined}
     */
    const bindings = function () {
        $('.add_new_search_row_handler').on('click', function () {
            let allow_remove = true;
            let allow_operator = true;
            if ($('.line.actual').length == 0) {
                allow_remove = false;
                allow_operator = false;
            }
            add_new_term_line(allow_remove, allow_operator);
        });

        $('.advance_option_search, .simple_option_search').on('click', function () {
            $('.line.actual').remove();
            let sURLVariables = [];
            sURLVariables.push('utf8=✓');
            sURLVariables.push('search_field=advanced');
            sURLVariables.push('q=');
            if ($(this).data('type') == 'simple') {
                $('.card-back').addClass('d-none');
                $('.card-front').removeClass('d-none');
                $('.flipcard').removeClass('flipped');
                $('.advance_option_search').removeClass('d-none');
                $('.simple_option_search').addClass('d-none');

                sURLVariables.push('search_type=simple');
                $('.search_field_selector_single').val('');
                $('.hidden_advance_search_single').val('');
                $('.simple_start_over').removeClass('d-none');
            } else {
                $('.card-back').removeClass('d-none');
                $('.card-front').addClass('d-none');

                sURLVariables.push('search_type=advance');
                if ($('.line.actual').length <= 0) {
                    add_new_term_line(false, false);
                }
                $('.simple_start_over').addClass('d-none');
                $('.flipcard').addClass('flipped');
                $('.advance_option_search').addClass('d-none');
                $('.simple_option_search').removeClass('d-none');

            }
        });

        $('.remove_tag_and_filter').on('click', function () {
            let indentifier = $(this).data('indentifier');
            if ($(this).data('is_main_element')) {
                var response = confirm('You are trying to remove the base criteria of the search. This will reset your search terms.');
                if (response == true) {
                    window.location = $(this).data('start-over-url');
                }
            } else {
                $('.server_node_' + indentifier).remove();
                $(this).parent('.tags_applied').remove();
                if (selfAdvanceSearchHandler.search_type == 'simple') {
                    $('.search_field_selector_single').val('');
                    $('.search_field_selector_hidden_single').val('');
                    $('.search-query-form').submit();
                } else {
                    $('.advanced').submit();
                }
            }


        });

        $('.advanced-search-submit').on('click', function () {
            let empty_value_found = false;
            $('.search_field_selector').each(function () {
                if (!$(this).hasClass('add_wanted_class')) {
                    if ($(this).val().trim() == '') {
                        empty_value_found = true;
                        return;
                    }
                }
            });

            if (selfAdvanceSearchHandler.search_type == 'simple') {
                empty_value_found = false;
            }

            if (empty_value_found) {
                jsMessages('danger', 'Search field cannot be empty!');
                e.preventDefault();
            }
        });

        $('.advanced').on('submit', function (e) {
            let empty_value_found = false;
            $('.search_field_selector').each(function () {
                if (!$(this).hasClass('add_wanted_class')) {
                    if ($(this).val().trim() == '') {
                        empty_value_found = true;
                        return;
                    }
                }
            });

            if (selfAdvanceSearchHandler.search_type == 'simple') {
                empty_value_found = false;
            }

            if (empty_value_found) {
                e.preventDefault();
            }

            if ($('.line.actual').length <= 0) {
                jsMessages('danger', 'You must have at-least 1 filter rows to do an advance search!');
                $('.org-edit-form').removeAttr('disabled');
                e.preventDefault();
            }

            setTimeout(function () {
                $('.advanced-search-submit').removeAttr('disabled');
            }, 30);
        });
        bind_advance_search_listing();
    }

    /**
     *
     * @param allow_remove
     * @param allow_operator
     * @param prepend
     * @returns {string}
     */
    const add_new_term_line = function (allow_remove, allow_operator) {
        if (typeof allow_remove == 'undefined') {
            allow_remove = true;
        }
        if (typeof allow_operator == 'undefined') {
            allow_operator = true;
        }
        if ($('.line.actual').length < 6) {
            let identifier = Math.random().toString(36).substring(2, 15);
            let new_element = $('.cloneable_search').clone();
            let parent_class = 'line_manager_' + identifier;
            new_element.find('.line').addClass('' + parent_class);
            let html = new_element.html();
            html = html.replace(/add_wanted_info/g, identifier);
            html = html.replace(/add_wanted_class/g, 'identifier_' + identifier);
            html = html.replace(/add_wanted_keyword_class/g, 'identifier_' + identifier);
            html = html.replace(/clone_able/g, 'actual');

            $('#lines_search_bar').append(html);
            if (allow_remove == false) {
                $('.' + parent_class + '  .remove_div_term').remove();
            }
            if (allow_operator == false) {
                $('.' + parent_class + '  .adjustable_area_advance_search input.form-control.search_field_selector').css('padding-right', '60px');
                $('.' + parent_class + '  .operator_term').remove();
            }
            if( allow_remove == false && allow_operator == false ){
                $('.' + parent_class + ' .adjustable_area_advance_search').removeClass('col-md-6').addClass('col-md-8');
            }
            bind_advance_search_listing();
            setTimeout(function () {
                $('.' + parent_class + ' .type_of_field_selector').selectize();
                $('.' + parent_class + ' .op_selector').selectize();
                $('.' + parent_class + ' .type_of_search').selectize();
            }, 50);
            if ($('.line.actual').length == 6) {
                $('.add_new_search_row_handler').hide();
            }
            return identifier;
        } else {
            $('.add_new_search_row_handler').hide();
        }
    };

    /**
     *
     * @param term_values
     * @param identifier
     */
    const set_term_field_values = function (term_values, identifier) {
        if (term_values) {
            $('.line_manager_' + identifier).addClass('server_node_' + term_values.key);
            let type_of_field_selector = $('.line_manager_' + identifier).find('.type_of_field_selector');

            let type_of_field_selector_selectize = type_of_field_selector[0].selectize;
            if (term_values.field && type_of_field_selector_selectize) {
                type_of_field_selector_selectize.setValue(term_values.field);
            }
            let op = $('.line_manager_' + identifier).find('.op_selector');

            if (op.length > 0) {
                let op_selectize = op[0].selectize;
                if (term_values.op && op_selectize) {
                    op_selectize.setValue(term_values.op);
                }
            }
            let type_of_search = $('.line_manager_' + identifier).find('.type_of_search.selectized');
            if (type_of_search.length > 0) {
                let type_of_search_selectize = type_of_search[0].selectize;
                if (term_values.type_of_search && type_of_search_selectize) {
                    type_of_search_selectize.setValue(term_values.type_of_search);
                }
            }
            $('.line_manager_' + identifier).find('.search_field_selector').val(term_values.keyword_searched);
            $('.line_manager_' + identifier).find('.' + term_values.field + '.search_field_selector_hidden').val(term_values.keyword_searched);
            $('.line_manager_' + identifier).find('.remove_current_line').attr('data-servernode', term_values.key);
            $('.line_manager_' + identifier).attr('data-servernode', term_values.key);
        }
    };

    const bind_advance_search_listing = function () {
        $('.remove_current_line').unbind('click');
        $('.remove_current_line').on('click', function () {
            $(this).parents('.line').remove();
            $('.add_new_search_row_handler').show();
            $('.pill-' + $(this).data('servernode')).click();

        });

        $('.type_of_field_selector').unbind('change');
        $('.type_of_field_selector').on('change', function () {
            let parent_line = $(this).parents('.line');
            parent_line.find('.hidden_advance_search').val('');
            parent_line.find('.' + $(this).val()).val(parent_line.find('.search_field_selector').val());
            parent_line.find('.op').val(parent_line.find('.op_selector').val());
        });

        $('.op_selector').unbind('change');
        $('.op_selector').on('change', function () {
            let parent_line = $(this).parents('.line');
            parent_line.find('.op').val(parent_line.find('.op_selector').val());
        });

        $('.search_field_selector').unbind('keyup');
        $('.search_field_selector').on('keyup', function () {
            let parent_line = $(this).parents('.line');
            let new_value = manage_field_value($(this).val(), 'advance');
            $(this).val(new_value);
            parent_line.find('.hidden_advance_search').val('');
            parent_line.find('.op').val(parent_line.find('.op_selector').val());
            parent_line.find('.' + parent_line.find('.type_of_field_selector').val()).val(parent_line.find('.search_field_selector').val());
        });

        $('.type_of_search').unbind('change');
        $('.type_of_search').change(function () {
            let parent_line = $(this).parents('.line');
            parent_line.find('.search_field_selector').val(manage_field_value(parent_line.find('.search_field_selector').val(), $(this).val(), 'advance'));
            parent_line.find('.type_of_search_field').val($(this).val());
        });

    };




}
