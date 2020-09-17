function Playlist() {
    /**
     * Playlist Management
     *
     * @author Furqan wasi <furqan@weareavp.com>
     *
     */

    var selfPL = this;

    this.dataTableObj;
    this.appHelper = {};
    this.start_time = 0;
    this.end_time = 0;
    this.max = 0;
    this.number_items_per_page = 20;
    this.collection_resource = {};
    this.time_range_regex = /^(\d{2}):(\d{2}):(\d{2})(\s)-(\s)(\d{2}):(\d{2}):(\d{2})$/;
    this.playlist_ajaxs = [];
    this.calls_inprogress = 0;

    var that = this;

    this.initialize = function () {
        selfPL.appHelper = new App();
        initDataTable();
        bindEvents();
        $('#public_access_time_period').daterangepicker({
            locale: {format: 'MM-DD-YYYY'}
        }, function (start, end) {
            that.collection_resource.setPeriodTimePeriod(start.format('MM-DD-YYYY'), end.format('MM-DD-YYYY'));
        });
        shareTabsPlaylist();

        list_playlist_items($('#playlist-list-page-no').val());
        searchPlaylistResource();

    };

    const bulkDeletePlaylistResources = function () {
        document_level_binding_element('.select_all_playlist_resources', 'click', function () {
            $(".choose-resource").prop('checked', true);
            $('.deselect_all_playlist_resources').show();
            $(this).hide();

        });

        document_level_binding_element('.deselect_all_playlist_resources', 'click', function () {
            $(".choose-resource").prop('checked', false);
            $('.select_all_playlist_resources').show();
            $(this).hide();
        });

        document_level_binding_element('#bulk_delete_playlist_resources', 'click', function () {

            let ids = [];
            $('.choose-resource:checked').each(function () {
                ids.push($(this).data('bulk_edit_playlist_resource_id'));
            });
            if (ids.length > 0) {
                $('#number_of_resource').text(ids.length);
                let fetch_resource_list_data = {
                    'playlist_resource_id': ids,
                    action: 'fetch_resource_list'
                };
                selfPL.appHelper.classAction($(this).data('fetch_resource_list'), fetch_resource_list_data, 'HTML', 'GET', '', selfPL, true);
            } else {
                jsMessages('danger', 'Please select atleast one resource.');
            }
        });
    };

    this.fetch_resource_list = function (response) {
        $('.bulk-edit-review-content').html('');
        $('.review_resources').DataTable().destroy();
        $('.bulk-edit-review-content').html(response);
        $('.review_resources').DataTable({
            pageLength: 10,
            bLengthChange: false,
            destroy: true,
            bInfo: true,
        });
        $('.bulk-edit-review-modal').modal();

        document_level_binding_element('.bulk-edit-do-it', 'click', function () {
            let ids = [];
            $('.choose-resource:checked').each(function () {
                ids.push($(this).data('bulk_edit_playlist_resource_id'));
            });

            let data = {
                'playlist_resource_id': ids,
                action: 'bulk_delete_playlist_resource'
            };
            selfPL.appHelper.classAction($('#bulk_delete_playlist_resources').data('url'), data, 'JSON', 'GET', '', selfPL, true);
            $('.loadingtextCus').html('Deleting Resources from playlist...');
        });
    };

    this.bulk_delete_playlist_resource = function (response) {
        jsMessages(response.status, response.msg);
        setTimeout(function () {
            location.reload();
        }, 2000)
    };

    const searchPlaylistResource = function () {
        document_level_binding_element('#search_playlist_resource', 'keyup', function (e) {
            var code = (e.keyCode || e.which);
            console.log(code);
            console.log(e);
            if (code == 37 || code == 38 || code == 39 || code == 40 || e.ctrlKey || e.altKey || e.shiftKey || code == '9') {
                return;
            }
            if ($('#search_playlist_resource').val().trim().length > 2 || $('#search_playlist_resource').val().trim().length == 0) {
                $('#playlist-list-contanier').html('');
                $('#playlist-list-page-no').val(0);
                list_playlist_items($('#playlist-list-page-no').val());
            }
        }, true);
    };

    const shareTabsPlaylist = function () {
        $('.share_tabs').on('mouseup', function () {
            let active_tab = $(this).data('tabname');
            setTimeout(function () {
                if (active_tab == 'public_access_url_tab') {
                    that.collection_resource.setPeriodTimePeriod($('#public_access_time_period').data('daterangepicker').startDate.format('MM-DD-YYYY'), $('#public_access_time_period').data('daterangepicker').endDate.format('MM-DD-YYYY'));
                }
            }, 500);
        });
    };

    this.handler_resource_playlist = function () {
        $('.add_to_resource_group').unbind('click');
        $('.add_to_resource_group').on('click', function () {
            let data = {
                action: 'add_resource_to_playlist',
                indentify: 'add_resource_to_playlist_reload',
                playlist_id: $('#playlist_id_current').val(),
                collection_resource_id: $(this).data('id'),
            };
            that.appHelper.classAction('/playlists/' + $('#playlist_id_current').val() + '/add_resource_to_playlist/' + $(this).data('id'), data, 'JSON', 'GET', '', that, true);
        });
    };

    this.edit_page_bindings = function () {
        that.bind_slider();
        edit_description_playlist();
        update_description_playlist();
        amount_slider_validation();
        description_detail();
        update_selected_tab();
        init_tinymce_for_element('.description_text', {
            selector: '.description_text',
            height: $('.description_text').attr('height'),
            plugins: 'link charmap hr anchor wordcount code lists',
            menubar: false,
            toolbar: "",
            branding: false
        });

        document_level_binding_element('#metadata-list-tab', 'click', function () {
            setTimeout(function () {
                scroll_to(".navbar.navbar-expand-lg.navbar-light", 1000);
            }, 200);
        });

        that.clip_time_picker();
        if (!that.playlist_show) {
            let collection = new Collection();
            collection.bindRSSFeed();
        }
        $('.best_in_place').best_in_place();
    };

    const description_detail = function () {
        const showChar = 220;  // How many characters are shown by default
        const ellipsestext = "...";
        const moretext = "Show more";
        const lesstext = "Show less";

        $('.playlist_description_full').each(function () {
            var content = $(this).html();
            if (content.length > showChar) {
                var c = content.substr(0, showChar);
                var h = content.substr(showChar, content.length - showChar);
                var html = c + '<span class="moreellipses">' + ellipsestext + '&nbsp;</span><span class="morecontent"><span>' + h + '</span>&nbsp;&nbsp;<a href="" class="morelink">' + moretext + '</a></span>';
                $(this).html(html);
            }
        });

        $(".morelink").click(function () {
            if ($(this).hasClass("less")) {
                $(this).removeClass("less");
                $(this).html(moretext);
            } else {
                $(this).addClass("less");
                $(this).html(lesstext);
            }
            $(this).parent().prev().toggle();
            $(this).prev().toggle();
            return false;
        });

    };
    this.clip_time_picker = function () {
        document_level_binding_element('.set_clip_end_time_custom, .set_clip_start_time_custom', 'click', function () {
            if (that.collection_resource && that.collection_resource.player_widget && that.collection_resource.player_widget.length > 0) {
                if ($(this).data('type') == 'start') {
                    $("#slider-range").slider("values", 0, that.collection_resource.player_widget[0].currentTime);
                } else {
                    $("#slider-range").slider("values", 1, that.collection_resource.player_widget[0].currentTime);
                }
                let response_time = check_valid_start_end_time($("#slider-range").slider("values", 0), $("#slider-range").slider("values", 1));
                $("#slider-range").slider("values", 0, response_time.start_time);
                $("#slider-range").slider("values", 1, response_time.end_time);
                update_range_values(response_time.start_time, response_time.end_time);
            }
        }, true);

    };
    /**
     *
     * @param start_time
     * @param end_time
     * @returns {{start_time: number, end_time: number}}
     */
    const check_valid_start_end_time = function (start_time, end_time) {
        if (start_time > that.max || start_time > end_time) {
            start_time = 0;
            jsMessages('danger', 'Start time cannot be greater than end time.');
        }

        if (start_time < 0)
            start_time = 0;

        if (end_time < start_time) {
            end_time = that.max;
            jsMessages('danger', 'End time cannot be less than start time.');
        }

        if (end_time > that.max) {
            end_time = that.max;
        }

        return {start_time: start_time, end_time: end_time}
    };

    const amount_slider_validation = function () {
        document_level_binding_element('.amount-slider', 'keyup', function () {
            if (!$(this).val().match(that.time_range_regex)) {
                $(this).attr('style', 'border: 1.3px solid red;');
            } else {
                let time_range = $(this).val().split('-');
                let start_time = humanToSeconds(time_range[0]);
                let end_time = humanToSeconds(time_range[1]);
                let response_time = check_valid_start_end_time(start_time, end_time);
                start_time = response_time.start_time;
                end_time = response_time.end_time;
                update_range_values(start_time, end_time);
                $("#slider-range").slider("values", 0, start_time);
                $("#slider-range").slider("values", 1, end_time);
                $(this).attr('style', 'border: 1px solid rgba(0, 0, 0, 0.1);');
            }
        }, true);
    };

    const update_selected_tab = function () {
        document_level_binding_element('.playlist_edit_tabs', 'click', function () {
            let data = {
                tabtype: $(this).data('tabtype'),
                action: 'update_selected_tab'
            };
            selfPL.appHelper.classAction($(this).data('urltab'), data, 'text', 'POST', '', selfPL, false);
        }, true);
    };

    const edit_description_playlist = function () {
        document_level_binding_element('.edit_description_playlist', 'click', function () {
            $('.update_description').data('url', $(this).data('url'));
            $('.update_description').data('playlist_resource_id', $(this).data('playlist_resource_id'));
            tinyMCE.get("description_text").setContent($('.playlist_resource_description_' + $(this).data('playlist_resource_id')).html())
        }, true);
    };

    const update_description_playlist = function () {
        document_level_binding_element('.update_description', 'click', function () {
            let data = {
                content: tinyMCE.activeEditor.getContent({format: 'raw'}),
                playlist_resource_id: $(this).data('playlist_resource_id'),
                action: 'update_description_playlist_action'
            };
            selfPL.appHelper.classAction($(this).data('url'), data, 'JSON', 'POST', '', selfPL, true);
        }, true);
    };

    const activate_playlist_search = function () {
        document_level_binding_element('#search_playlist_for_resource', 'keyup', function () {
            var value = $(this).val().toLowerCase();
            $(".add_to_playlist_container .playlist_title").filter(function () {
                $(this).closest('.card').toggle($(this).text().toLowerCase().indexOf(value) > -1)
            });
        }, true);

    };

    const list_playlist_items = function (page_number) {
        $('.loader-playlist_items').removeClass('d-none');
        selfPL.calls_inprogress++;
        let data = {
            per_page: selfPL.number_items_per_page,
            page_number: page_number,
            view_type: selfPL.playlist_show,
            query: $('#search_playlist_resource').val().trim().toLowerCase(),
            action: 'list_playlist_items_action'
        };
        $.each(selfPL.playlist_ajaxs, function (index) {
            this.abort();
            delete selfPL.playlist_ajaxs[index];
        });
        selfPL.playlist_ajaxs = [];
        let object_ajax = selfPL.appHelper.classAction($('#playlist-list-contanier').data('url'), data, 'HTML', 'GET', '', selfPL, false);
        selfPL.playlist_ajaxs.push(object_ajax);
    };

    this.list_playlist_items_action = function (response, _container, requestData) {

        $('#playlist-list-page-no').val(parseInt($('#playlist-list-page-no').val(), 10) + 1);
        $('#playlist-list-contanier').append(response);
        setTimeout(function () {

            bulkDeletePlaylistResources();
            if (selfPL.playlist_show == false || selfPL.playlist_show == 'false') {
                init_sortable();
                $('.best_in_place').best_in_place();
                $('#no_resource_found').hide();
                $('#playlist_resources_count').text($('.playlist_resource_single:visible').length);
            }

            $('.playlist_resource_description').each(function () {
                let content = $(this).children('.less-description').html();
                let show_Char =120;
                if (content.length > show_Char) {
                    let c = content.substr(0, show_Char);
                    c = c.substr(0, c.lastIndexOf(" "));
                    var html = c + '<span class="moreellipses">...&nbsp;</span>&nbsp;&nbsp;<span class="lessToMore">Show more</span>';
                    $(this).children('.less-description').html(html);
                    $(this).children('.full-description').append('<span class="moreToLess">Show less</span>')
                }
            });
            $('.lessToMore').click(function () {
                $(this).parent().addClass('d-none');
                $(this).parent().next().removeClass('d-none');
            });
            $('.moreToLess').click(function () {
                $(this).parent().addClass('d-none');
                $(this).parent().prev().removeClass('d-none');
            });
            $(".title_description, .less-description, .full-description").unmark();
            $(".title_description, .less-description, .full-description").mark(requestData['query'].trim(), {
                "element": "span",
                "className": "highlight-marker ",
                "caseSensitive": false,
                "separateWordSearch": false
            });

        }, 500);
        selfPL.calls_inprogress--;
        if (selfPL.calls_inprogress == 0) {
            $('.loader-playlist_items').addClass('d-none');
        }
        setTimeout(function(){
            if ($('.playlist_resource_single').length == 0 && selfPL.calls_inprogress <= 0) {
                $('#no_resource_found').show();
            }
        }, 1000);


    };

    this.update_description_playlist_action = function (response, _container, request) {
        if (response.state == 'success') {
            $('.playlist_resource_description_' + request.playlist_resource_id).html(request.content);
            $('.playlist_resource_description_' + request.playlist_resource_id).tooltip('hide').attr('data-original-title', request.content);
            $('#edit_playlist_resource_description_modal_center').modal('hide');
            jsMessages('success', response.msg);
        } else {
            jsMessages('danger', response.msg);
        }
        setTimeout(function () {
            location.reload();
        }, 500);

    };

    this.bind_slider = function () {
        $("#slider-range").slider({
            range: true,
            step: 0.01,
            min: 0.0,
            max: that.max,
            values: [that.start_time, that.end_time],
            slide: function (event, ui) {
                update_range_values(ui.values[0], ui.values[1]);
            }
        });
        update_range_values($("#slider-range").slider("values", 0), $("#slider-range").slider("values", 1));
    };

    const initDataTable = function () {
        let dataTableElement = $('#playlist_data_table');
        if (dataTableElement.length > 0) {
            this.dataTableObj = dataTableElement.DataTable({
                responsive: true,
                pageLength: 100,
                bInfo: true,
                destroy: true,
                bLengthChange: false,
                pagingType: 'simple_numbers',
                'dom': "<'row'<'col-md-6'f><'col-md-6'p>>" +
                    "<'row'<'col-md-12'tr>>" +
                    "<'row'<'col-md-5'i><'col-md-7'p>>",
                language: {
                    info: 'Showing _START_ - _END_ of _TOTAL_',
                    infoFiltered: '',
                    zeroRecords: 'No Playlist found.',
                },
                columnDefs: [
                    {orderable: false, targets: -1}
                ],
                initComplete: function (settings) {
                    initDeletePopup();
                }
            });
        }
    };

    const update_range_values = function (start, end) {
        let time_range = range_time_manager(start, end);
        $("#amount").val("" + time_range.start.hours + ':' + time_range.start.minutes + ":" + time_range.start.seconds + " - " + time_range.end.hours + ':' + time_range.end.minutes + ":" + time_range.end.seconds);
    };

    const get_minutes_hrs_seconds = function (time) {
        return secondsToHumanHash(time);
    };

    const range_time_manager = function (range_start, range_end) {
        let hour_start, minute_start, seconds_start, hour_end, minute_end, seconds_end;
        let range_start_response = get_minutes_hrs_seconds(range_start);
        minute_start = range_start_response.minute;
        seconds_start = range_start_response.seconds;
        hour_start = range_start_response.hour;

        let range_end_response = get_minutes_hrs_seconds(range_end);
        minute_end = range_end_response.minute;
        seconds_end = range_end_response.seconds;
        hour_end = range_end_response.hour;

        return {
            start: {hours: hour_start, minutes: minute_start, seconds: seconds_start},
            end: {hours: hour_end, minutes: minute_end, seconds: seconds_end}
        }
    };

    const resetSlider = function () {
        var $slider = $("#slider-range");
        $slider.slider("values", 0, 0.0);
        $slider.slider("values", 1, $("#slider-range").slider('option').max);
    };

    const bindEvents = function () {

        toggle_item_playlist();
        update_time_range();
        $("#playlist-list-contanier").on('scroll', function () {
            if ($(this).scrollTop() + $(this).innerHeight() >= $(this)[0].scrollHeight) {
                list_playlist_items($('#playlist-list-page-no').val());
            }
        });
        // TODO:: sort field change feature playlist
        // binding_on_sorting_field_change();
    };
    const toggle_item_playlist = function () {
        $(document).on('click', '.choose-file', function (event) {
            // if chosen file is current active file, copy values of time range slider to the form
            if ($(this).data('fileid') == $('#mediafile_current').val()) {
                $('#start_time_' + $(this).data('fileid')).val($("#slider-range").slider("values", 0));
                $('#end_time_' + $(this).data('fileid')).val($("#slider-range").slider("values", 1));
            }

            let form = $(this).closest('form');
            let url = $(form).attr('action');
            let data = form.serializeArray();
            data['action'] = 'action__toggle_item_playlist';
            let method = form.attr('method');
            selfPL.appHelper.classAction(url, data, 'JSON', method, '', selfPL, false);
        });
    };

    const update_time_range = function () {
        $(document).on('click', '.update_time_range', function (event) {
            if (!$('.amount-slider').val().match(that.time_range_regex)) {
                jsMessages('danger', 'Invalid clip time slot provided.');
                return false;
            }
            $('#time_range_loader').removeClass('d-none');
            $('#start_time_current_update').val($("#slider-range").slider("values", 0));
            $('#end_time_current_update').val($("#slider-range").slider("values", 1));
            let data = {
                start_time: $('#start_time_current_update').val(),
                end_time: $('#end_time_current_update').val(),
                time_only: true,
                mediafile: $('#mediafile_current').val(),
                action: 'action__update_time_range'
            };
            selfPL.appHelper.classAction($('#url_for_range').data('url'), data, 'JSON', 'POST', '', selfPL, false);
        });
    };
    /**
     *
     * @param response
     */
    this.action__toggle_item_playlist = function (response) {
        try {
            if (response.state == 'success') {
                jsMessages('success', response.msg);
            } else if (typeof response.msg != 'undefined') {
                jsMessages('danger', response.msg);
                location.reload();
            } else {
                jsMessages('danger', 'Something went wrong. Please try again');
                location.reload();
            }
        } catch (err) {
            console.log(err);
        }
    };

    this.action__update_time_range = function (response) {
        if (response.state == 'success') {
            // updated media-url link
            var url = $('.playing').attr('data-media-url');
            url = url.split("?")[0];
            var start_time = parseInt($('#start_time_current_update').val(), 10);
            $('.playing').attr('data-media-url', url + '?t=' + start_time);

            // tick the checkbox
            $('.playing').parent().find('.choose-file').attr('checked', 'checked');
            $('.playing').parent().find('.choose-file').prop('checked', true);
            jsMessages('success', response.msg);
        } else {
            jsMessages('danger', 'Something went wrong. Please try again');
        }
        $('#time_range_loader').addClass('d-none');
    };

    const binding_on_sorting_field_change = function () {
        document_level_binding_element('.plr-sort-index', 'change', function () {
            let current_element = this;
            let current_value = $(this).val();
            let last_element = $('.ui-sortable-handle')[0];
            $('.plr-sort-index').each(function (i, e) {
                if (parseInt($(this).val(), 10) >= parseInt(current_value, 10) && current_element != this)
                    return false;
                last_element = $(this).closest('.ui-sortable-handle');
            });
            if (last_element)
                $($(this).closest('.ui-sortable-handle')).insertAfter(last_element);
            setTimeout(function () {
                update_sort_counts();
                update_sort_info();
            }, 100);

        }, true);
    };

    const update_sort_counts = function () {
        let k = 1;
        $('.plr-sort-index').each(function (i, e) {
            $(e).val(k);
            k++;
        });
    };
    const init_sortable = function () {
        $('.playlist-list').sortable({
            update: function (event, ui) {
                let data = $(this).sortable('toArray');
                that.updateSortField(data);
                update_sort_info();
            }
        })
    };

    const update_sort_info = function () {
        let sorts = {};
        $('.plr-sort-index').each(function () {
            sorts[$(this).data('id')] = $(this).val();
        });
        $('.loader-playlist-panel').removeClass('d-none');
        let data = {
            action: 'sort_playlist_resources',
            resources: sorts,
        };
        that.appHelper.classAction($('#resource-list-container').data('url'), data, 'JSON', 'POST', '', that, false);
    };

    /**
     *
     * @param response
     */
    this.sort_playlist_resources = function (response) {
        $('.loader-playlist-panel').addClass('d-none');
        if (response.responseText == 'Success') {
            jsMessages('success', 'Playlist sorted');
        } else {
            jsMessages('danger', 'Something went wrong. Please try again');
        }
    };

    /**
     *
     * @param data
     */
    this.updateSortField = function (data) {
        var counter = 1;
        $.each(data, function (index, id) {
            if ($('#' + id + ' .plr-sort-index').length > 0) {
                $('#' + id + ' .plr-sort-index').val(counter);
                counter++;
            }
        });

    };

    const initDeletePopup = function () {
        $('.playlist_delete').click(function () {
            $('#modalPopupBody').html('Are you sure you want to delete this playlist? There is no undoing this action.');
            $('#modalPopupTitle').html('Delete "' + $(this).data().name + '" Playlist');
            $('#modalPopupFooterYes').attr('href', $(this).data().url);
            $('#modalPopup').modal('show');
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

    const initialize_add_resource_playlist = function () {
        that.appHelper = new App();
    };

    this.initialize_playlist_detail_page = function () {
        initialize_add_resource_playlist();
        if ($('#type_of_playlist_view').val() == 'add_to_playlist_view') {
            load_playlist();
        } else {
            resource_playlist_only();
        }
        activate_playlist_search();
    };

    this.initialize_playlist_search_page = function () {
        initialize_add_resource_playlist();
        add_to_playlist_search_page();
        activate_playlist_search();
    };

    const add_to_playlist_search_page = function () {
        bindingElement('.add_to_playlist_search_page', 'click', function () {
            fetch_playlist($(this).data('organizationid'), $(this).data('resourceid'), $(this).data('url'), 'listing_for_add_to_playlist');
        }, true);
    };

    const resource_playlist_only = function () {
        fetch_playlist($('.resource_playlists_container').data('organizationid'), $('.resource_playlists_container').data('resourceid'), $('.resource_playlists_container').data('url'), 'listing_resource_playlists');
    };

    const load_playlist = function () {
        fetch_playlist($('.add_to_playlist_container').data('organizationid'), $('.add_to_playlist_container').data('resourceid'), $('.add_to_playlist_container').data('url'), 'listing_for_add_to_playlist');
    };

    /**
     *
     * @param organization_id
     * @param resource_id
     * @param url
     */
    const fetch_playlist = function (organization_id, resource_id, url, action) {
        let data = {
            action: action,
            identifier: action,
            organization_id: organization_id,
            collection_resource_id: resource_id
        };
        that.appHelper.classAction(url, data, 'HTML', 'GET', '', that, false);
    };

    const add_resource_to_playlist_action = function () {
        bindingElement('.add_resource_to_playlist', 'click', function () {
            $('#playlist_loader_' + $(this).data('playlistid')).removeClass('d-none');
            let data = {
                action: 'add_resource_to_playlist',
                playlist_id: $(this).data('playlistid'),
                collection_resource_id: $(this).data('resourceid'),
            };
            that.appHelper.classAction($(this).data('url'), data, 'JSON', 'GET', '', that, false);
        }, true);
    };

    const create_playlist = function () {
        bindingElement('.create_playlist', 'click', function () {
            let data = {
                action: 'create_playlist',
                playlist: {name: $('#playlist_title').val()},
                collection_resource_id: $('#playlist_title').data('resourceid')
            };
            that.appHelper.classAction($(this).data('url'), data, 'HTML', 'POST', '', that, true);
        }, true);
    };

    /**
     *
     * @param response
     * @param container
     * @param request
     */
    this.add_resource_to_playlist = function (response, container, request) {
        let type = 'danger';
        if (response.status == '202') {
            type = 'success';
            $('#playlistModalCenter').modal('hide');
        }
        jsMessages(type, response.responseText);
        $('.playlist_loader').addClass('d-none');
        $('.adding_playlist_text').addClass('d-none');
        if (request.indentify == 'add_resource_to_playlist_reload') {
            setTimeout(function () {
                location.reload();
            }, 400);
        }
    };

    /**
     * @param response
     */
    this.create_playlist = function (response) {
        let type = 'danger';
        let message = 'Playlist not created. Please try again!'
        if (response || 0 !== response.length) {
            type = 'success';
            message = 'Playlist successfully created!';
            $('#playlist_title').val('');
            $('.listing_for_add_to_playlist_accordian').append(response);
            add_resource_to_playlist_action();
            $('#accordionPlaylist').animate({
                scrollTop: $('#accordionPlaylist').offset().top
            }, 1200);
            tooltip_init();
        }
        jsMessages(type, message);
    };
    const tooltip_init = function () {
        setTimeout(function () {
            initToolTip(false);
        }, 100);
    };
    /**
     *
     * @param response
     */
    this.listing_for_add_to_playlist = function (response) {
        if (response || 0 !== response.length) {
            $('.add_to_playlist_container_body').html(response);
            add_resource_to_playlist_action();
            create_playlist();
            resource_playlist_only();
        }
    };
    /**
     *
     * @param response
     */
    this.listing_resource_playlists = function (response) {
        if (response || 0 !== response.length) {
            $('.resource_playlist_container_body').html(response);
            tooltip_init();
        }
    };
}
