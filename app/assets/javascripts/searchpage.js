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

var selfSearchPage;

function SearchPage() {
    selfSearchPage = this;
    selfSearchPage.appHelper = new App();

    /**
     *
     * @returns {none}
     */
    this.initialize = function () {
        bindings();
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

    this.assignToPlaylist = function (response) {
        if (response.status === 202) {
            jsMessages('success', response.responseText);
        } else {
            jsMessages('danger', response.responseText);
        }
        setTimeout(function () {
            location.reload();
        }, 1000)

    };

    const updateSelectedPlaylist = function (type, status, id) {
        let ids = [];
        ids.push(id);
        callSelectedPlaylist(ids, type, status);
    };

    const callSelectedPlaylist = function (ids, type, status) {
        let updateResourceListData = {
            'playlist_resource_id': ids,
            type,
            status,
            action: 'fetchResourceList'
        };
        selfSearchPage.appHelper.classAction($('#update_selected_playlist_catalog_url').data('url'), updateResourceListData, 'JSON', 'POST', '', selfSearchPage, true);
    };

    const assignToPlaylist = function () {
        document_level_binding_element('.bulk-add-to-playlist ', 'click', function () {
            let selectPlaylist = $('#select_playlist').selectize();
            let selectize = selectPlaylist[0].selectize;
            if (selectize.getValue().trim() !== '') {
                let assignToPlaylist = {
                    'select_playlist': selectize.getValue(),
                    action: 'assignToPlaylist'
                };
                selfSearchPage.appHelper.classAction($(this).data('url'), assignToPlaylist, 'JSON', 'POST', '', selfSearchPage, true);
            } else {
                jsMessages('danger', 'Please select playlist and try again!')
            }
        });
    };

    this.getAllIds = function (response) {
        let playlistResourceIds = [];
        $.each(response.response.docs, function () {
            playlistResourceIds.push(this['id_is']);
        });
        callSelectedPlaylist(playlistResourceIds, 'bulk', 'all');
    };

    this.fetchResourceList = function (response) {
        try {
            $('#number_of_selected_resources').html(response);
            $('#number_of_selected_resource_list').html(response);
        } catch (e) {
            $('#number_of_selected_resources').html(0);
            $('#number_of_selected_resource_list').html(0);
        }

    };

    this.fetchBulkEditResourceList = function (response) {
        $('.bulk-edit-review-playlist-content').html('');
        $('.bulk-edit-review-playlist-modal').modal();
        $('.review_resources').DataTable().destroy();
        $('.bulk-edit-review-playlist-content').html(response);
        $('.review_resources').DataTable({
            pageLength: 10,
            bLengthChange: false,
            destroy: true,
            bInfo: true,
        });
    };

    this.fetchBulkEditResourceListExp = function (response) {
        $('.bulk-edit-review-resource-list-content').html('');
        $('.bulk-edit-review-resource-list-modal').modal();
        $('.review_resources-list').DataTable().destroy();
        $('.bulk-edit-review-resource-list-content').html(response);
        $('.review_resources-list').DataTable({
            pageLength: 10,
            bLengthChange: false,
            destroy: true,
            bInfo: true,
        });
    };

    const searchFacets = function () {
        document_level_binding_element('.search_facet', 'keyup', function () {
            var targetid = $(this).data('target');
            var value = $(this).val().trim().toLowerCase();
            $("#facet-" + targetid + " .facet-values li .facet_value_custom").filter(function () {
                $(this).closest("li").toggle($(this).text().trim().toLowerCase().indexOf(value) > -1)
            });
        });
    };

    /**
     * Bind all elements
     *
     * @returns {undefined}
     */
    const bindings = function () {
        assignToPlaylist();
        searchFacets();
        document_level_binding_element('#add_to_playlist ', 'click', function () {
            if ($('#number_of_selected_resources').html().trim() === '' || $('#number_of_selected_resources').html().trim() === '0') {
                jsMessages('danger', 'Please select atleast one resource.');
            } else {
                let resourceListing = {
                    action: 'fetchBulkEditResourceList',
                };
                selfSearchPage.appHelper.classAction($(this).data('url'), resourceListing, 'HTML', 'GET', '', selfSearchPage, true);
            }
        });

        document_level_binding_element('.bulk_add_to_playlist ', 'click', function () {
            updateSelectedPlaylist('single', $(this).prop('checked'), $(this).data('id'));
        });

        document_level_binding_element('#select_all, #deselect_all ', 'click', function () {
            if ($(this).data('type') === 'select') {
                $('.bulk_add_to_playlist').prop('checked', true);
                $('#number_of_selected_resources').html($('.bulk_add_to_playlist').length);
                $('#number_of_selected_resource_list').html($('.bulk_add_to_playlist').length);
                let ids = []
                $('.bulk_add_to_playlist').each(function(i,v){
                    ids.push( $(v).data('id') );
                });
                callSelectedPlaylist(ids, 'bulk', 'all');
            } else {
                $('.bulk_add_to_playlist').prop('checked', false);
                $('#number_of_selected_resources').html(0);
                $('#number_of_selected_resource_list').html(0);
            }
            if ($(this).data('type') === 'select') {
                let getAllIds = {
                    action: 'getAllIds',
                };
                selfSearchPage.appHelper.classAction(window.location.href, getAllIds, 'JSON', 'POST', '', selfSearchPage, true);
            } else {
                callSelectedPlaylist([], 'bulk', 'all');
            }
        });

        $('.type_of_field_selector_single').on('change', function () {
            $('.hidden_advance_search_single').val('');
            $('.search-query-form').find('.' + $(this).val() + '_single').val($('.search_field_selector_single').val());
        });

        $('.search_field_selector_single').on('keyup', function () {
            let new_value = manage_field_value($(this).val(), 'simple ');
            $(this).val(new_value);
            $('.hidden_advance_search_single').val('');
            $('.search-query-form').find('.' + $('.type_of_field_selector_single').val() + '_single').val($(this).val());
        });

        document_level_binding_element('#add_to_resource_list ', 'click', function () {
            if ($('#number_of_selected_resources').html().trim() === '' || $('#number_of_selected_resources').html().trim() === '0') {
                jsMessages('danger', 'Please select atleast one resource.');
            } else {
                let resourceListing = {
                    action: 'fetchBulkEditResourceListExp',
                };
                selfSearchPage.appHelper.classAction($(this).data('url') + '?type=collection_resource_file_list', resourceListing, 'HTML', 'GET', '', selfSearchPage, true);
            }
        });

        document_level_binding_element('.bulk-add-to-resource_list', 'click', function () {
            selfApp.show_loader();
            var notes = document.getElementsByName('crfl_note[]');
            var ids = document.getElementsByName('crfl_id[]');
            var payload = []
            for (var i = 0; i < notes.length; i++) {
                if( ids[i] != undefined )
                    payload.push( {resource_id: ids[i].value, note: notes[i].value} )
            }

            $.ajax({
                url: $(this).data('url'),
                data: {payload: JSON.stringify(payload)},
                error: function (response) {
                    console.log( 'payload: ', payload );
                    console.log( 'response: ', response );
                    selfApp.hide_loader();
                    jsMessages('danger', "We're sorry, something went wrong.");
                    setTimeout(function(){ window.location.reload(); }, 1000);
                },
                success: function (response) {
                    selfApp.hide_loader();
                    jsMessages('success', 'Resource list updated successfully.');
                    $('.bulk-edit-review-resource-list-modal').modal('hide');
                    setTimeout(function(){ window.location.reload(); }, 1000);
                },
                type: 'POST'
            });

        });

        $('.range_duration').on('click', function () {
            $(this).select();
        });

        $('.range_duration').on('keyup', function () {
            var reg = /^\d+$/;
            if ($(this).val() < 0 || !$(this).val().match(reg)) {
                $(this).val('');
            }
        });

        $('.description_duration_ls_validator').on('click', function (e) {
            if ($('#hrs_start').val().trim() == '' || $('#hrs_end').val().trim() == '' || $('#minutes_start').val().trim() == '' || $('#minutes_end').val().trim() == '') {
                jsMessages('danger', 'Duration fields cannot be empty.');
                e.preventDefault();
                setTimeout(function () {
                    $('.description_duration_ls_validator').removeAttr('disabled');
                }, 200);
            }
        });

        $('#hrs_start, #hrs_end, #minutes_start, #minutes_end').on('keyup', function () {
            if (parseInt($(this).val(), 10)) {
                $(this).val(parseInt($(this).val(), 10));
            }
            let max_chars = 2;
            if ($(this).val().length >= max_chars) {
                $(this).val($(this).val().substr(0, max_chars));
            }
        });

        $('#hrs_start, #hrs_end').on('keyup', function () {
            if ($(this).val() > 23) {
                $(this).val(23);
            }
        });

        $('#minutes_start, #minutes_end').on('keyup', function () {
            if ($(this).val() > 59) {
                $(this).val(59);
            }
        });

        $('#hrs_start, #hrs_end').on('keyup', function () {
            if ($(this).val() > 23) {
                $(this).val(23);
            }
        });

        $('#minutes_start, #minutes_end').on('keyup', function () {
            if ($(this).val() > 59) {
                $(this).val(59);
            }
        });

        var sPageURL = decodeURIComponent(window.location.search.substring(1)), sURLVariables = sPageURL.split('&');
        for (var i = 0; i < sURLVariables.length; i++) {
            if (sURLVariables[i] === 'update_advance_search=update_advance_search' || sURLVariables[i] === 'reset_facets=true' || sURLVariables[i] === 'update_facets=true' || sURLVariables[i] === 'start_over_search=true') {
                sURLVariables.splice(i, 1);
            }
        }

        window.history.replaceState({}, document.title, window.location.pathname + '?' + sURLVariables.join('&'));
        setTimeout(function () {
            document.querySelectorAll('.search_tombstone_cust').forEach(function (element) {
                if ((element.offsetHeight + 5 < element.scrollHeight) || ((element.offsetWidth) < element.scrollWidth)) {
                    // your element have overflow
                    element.parentElement.getElementsByClassName("moreclick")[0].style.display = "block";
                }
            });
            $('.custom-modal-normal .btn-close').on('click', function () {
                $('.custom-modal-normal').hide();
            });
            $('.moreclick').on('click', function () {
                $('.custom-modal-normal').hide();
                $('#' + $(this).data('id')).show();
            });

            $('.search_range_picker_date.range_begin, .search_range_picker_date.range_end').daterangepicker({
                locale: {
                    format: 'YYYY-MM-DD',
                }, ranges: {
                    'Today': [moment(), moment()],
                    'Yesterday': [moment().subtract(1, 'days'), moment().subtract(1, 'days')],
                    'Last 7 Days': [moment().subtract(6, 'days'), moment()],
                    'Last 30 Days': [moment().subtract(29, 'days'), moment()],
                    'This Month': [moment().startOf('month'), moment().endOf('month')],
                    'Last Month': [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]
                }
            });
        }, 100);

        $('.checked-facets').on('click', function () {
            window.location = $(this).data('linkremove');
        });
        $('.search-field-blacklight').val('');
        $('.search-field-blacklight').attr('placeholder', 'Search');

        $('.range_duration').keyup(function () {
            if ($(this).val() < 0) {
                $(this).val(0);
            }
        });

        $('.description_duration_ls_validator').click(function (e) {
            var hrs_start = parseInt($('#hrs_start').val(), 10);
            var minutes_start = parseInt($('#minutes_start').val(), 10);
            var hrs_end = parseInt($('#hrs_end').val(), 10);
            var minutes_end = parseInt($('#minutes_end').val(), 10);

            var start_time = (hrs_start * 60) + minutes_start;
            var end_time = (hrs_end * 60) + minutes_end;
            var clear = true;
            var msg = '';

            if (start_time >= end_time) {
                clear = false;
                msg = 'Start Duration cant be greater then or equals to End Duration ';
            }
            if (clear == false) {
                selfSearchPage.appHelper.show_modal_message('Duration Filter', 'Invalid Duration Filter values. ' + msg, 'danger');
                $('.range_duration').attr('style', 'border-color:red;');
                e.preventDefault();
                return false;
            } else {
                $('.range_duration').attr('style', 'border: 1px solid #ced4da;');

            }
            $('#range_description_duration_ls_begin').val(start_time);
            $('#range_description_duration_ls_end').val(end_time);
        });
        $('.search_field_selector_single').keyup(function (event) {
            if (event.keyCode == 13) {
                // Following code is commented to give user sort choice preference. 'title_ss asc' is now the default choice
                // if ($(".search_field_selector_single").val() == '') {
                //     $('<input>').attr({
                //         type: 'hidden',
                //         name: 'sort',
                //         value: 'title_ss asc'
                //     }).appendTo('.simple_search');
                // }
                $('.simple_search').submit();
            }
        });
    };
}
