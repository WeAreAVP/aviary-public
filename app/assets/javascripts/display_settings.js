/**
 * Display Settings Management
 *
 * @author Furqan Wasi <furqan@weareavp.com>
 *
 */

function DisplaySettings() {
    var that = this;
    this.Filters = new Array();
    this.load_resource_again = true;
    this.page_number = 1;

    this.handlecallback = function (response, container, requestData) {
        try {
            eval('this.' + requestData.action + '(response,container,requestData)');
        } catch (err) {
            console.log(err);
        }
    };

    this.resources_home_notfeatured = function (response) {
        $('#resources_home-notfeatured .home-featured-resources').append(response.partial);
        setTimeout(function () {
            if (response.partial.includes("resource-detail-data")) {
                let childnumber = 1;
                if (that.page_number > 1) {
                    childnumber = (that.page_number - 1) * 8
                }
                if ($('.home-featured-resources .col-3:nth-last-child(' + childnumber + ')').offset()) {
                    $('html, body').animate({
                        scrollTop: ($('.home-featured-resources .col-3:nth-last-child(' + childnumber + ')').offset().top - 370)
                    }, 500);
                }
                setTimeout(function () {
                    that.load_resource_again = true;
                    if ($(window).scrollTop() + $(window).height() == $(document).height() && that.load_resource_again == true) {
                        call_lazy_loader();
                    }
                }, 1000);
            }
            $('#loader-gif-laxy').addClass('d-none');

        }, 100);

    };

    this.continues_loading = function () {
        that.app_helper = new App();
        $(window).scroll(function () {
            let elem = $('#resources_home-notfeatured');
            var docViewTop = $(window).scrollTop();
            var docViewBottom = docViewTop + $(window).height();

            var elemTop = $(elem).offset().top;
            var elemBottom = elemTop + $(elem).height();
            if ((elemBottom <= docViewBottom) && that.load_resource_again == true && $('#resources_home-notfeatured .home-featured-resources').length) {
                call_lazy_loader();
            }
        });
    };
    this.toggleCollectionSection = function () {
        $('.link-toggle-collection a').click(function (e) {
            e.preventDefault();
            $('#collection_resource_container').slideToggle('slow');
            $('#about_collection_container').slideToggle('slow');
        });

    };
    const call_lazy_loader = function () {
        $('#loader-gif-laxy').removeClass('d-none');
        that.load_resource_again = false;
        let data = {
            action: 'resources_home_notfeatured',
            page_number: that.page_number,
            from_lazy_load: true,
        };
        that.page_number++;
        that.app_helper.classAction($('#resources_home-notfeatured').data('url'), data, 'JSON', 'GET', '', that, false);
    }

    this.init_display_settings = function (triggered_from) {
        removeImageCustom();
        let banner_type = $('#' + triggered_from + '_banner_type');
        let banner_title_type = $('#' + triggered_from + '_banner_title_type');

        $('.edit_' + triggered_from).submit(function (e) {
            if ($.trim($('#' + triggered_from + '_banner_slider_resources').val()) == '' && $('#' + triggered_from + '_banner_type').val() == 'featured_resources_slider') {
                jsMessages('danger', 'You must have at least one Resources for banner slider!');
                e.preventDefault();
            }
        });


        $('.color_picker').minicolors({
            changeDelay: 0,
            theme: "bootstrap",
            defaultValue: "#000000",
            letterCase: "lowercase",
            animationSpeed: 50,
            animationEasing: "swing"
        });
        manage_form_banner_visibility(banner_type);
        manage_form_banner_title_visibility(banner_title_type);

        $(banner_type).on('change', function () {
            manage_form_banner_visibility(this);
        });

        $(banner_title_type).on('change', function () {
            manage_form_banner_title_visibility(this);
        });

        $('#banner_slider_resources_info').autocomplete({
            source: $('#banner_slider_resources_info').data("url"),
            minLength: 2,
            select: function (event, ui) {
                if (that.Filters.length > 5)
                    jsMessages('danger', 'You cannot add more then 5 Resources!');
                else
                    addToken(triggered_from + '_banner_slider_resources', ui.item);
            },
            close: function () {
                $('#banner_slider_resources_info').val('');
            }
        });

        AddExistingData(triggered_from);
        $('#' + triggered_from + '_banner_slider_resources_table').DataTable();

    };

    const AddExistingData = function (triggered_from) {
        $('#banner_slider_resources_info').keydown(function (event) {
            if (event.keyCode == 13) {
                event.preventDefault();
                return false;
            }
        });
        let value = triggered_from + '_banner_slider_resources';
        if ($('#' + value).val() != '' && typeof $('#' + value).val() != 'undefined') {
            that.Filters = JSON.parse($('#' + value).val());
            let existingInfo = that.Filters;
            if (existingInfo.length > 0) {
                for (let cnt in existingInfo) {
                    let display = existingInfo[cnt].value;
                    let label = '';
                    display = existingInfo[cnt].id;
                    label = '<td>' + existingInfo[cnt].value + '</td>';

                    let html = '<tr id="' + value + '_' + cnt + '"><td>' +
                        display + '</td>' + label + '<td><a href="javascript://" data-type="' + value + '" data-index="' + cnt + '" class="btn-sm btn-danger remove_btn">Remove</a></td>' +
                        '</tr>';
                    $('#' + value + '_container').append(html);
                }
            }
        }

        bindRemoveEvent();
    };

    const addToken = function (field, item) {
        let currentFieldValue = $.trim($('#' + field).val());
        if (currentFieldValue != '' && currentFieldValue != '""')
            that.Filters = JSON.parse(currentFieldValue);
        for (var x in that.Filters) {
            if (that.Filters[x].id == item.id) {
                jsMessages('danger', item.value + ' already exists.! ');
                return false;
            }
        }

        var temp = {};
        temp.id = item.id;
        temp.value = item.value;
        temp.type = field;
        that.Filters.push(temp);
        let currentIndex = that.Filters.length - 1;
        let display = item.id;
        let label = '<td>' + item.value + '</td>';
        setTimeout(function () {
            $('#' + field).val(JSON.stringify(that.Filters));
        }, 200);
        let html = '<tr id="' + field + '_' + currentIndex + '"><td>' +
            display + '</td>' + label + '<td><a href="javascript://" data-type="' + field + '" data-index="' + currentIndex + '" class="btn-sm btn-danger remove_btn">Remove</a></td>' +
            '</tr>';
        let dt = $('#' + field + '_table').DataTable();
        dt.row.add($(html));
        dt.draw();
        bindRemoveEvent();

    };

    const bindRemoveEvent = function () {
        $('.remove_btn').unbind('click').click(function () {
            removeToken($(this).data('type'), $(this).data('index'));
        });
    };

    const removeToken = function (field, index) {
        that.Filters = JSON.parse($('#' + field).val());
        delete (that.Filters[index]);
        that.Filters.splice(index, 1);
        let dt = $('#' + field + '_table').DataTable();
        dt.row($('#' + field + '_' + index)).remove();
        dt.draw();
        if (that.Filters.length > 0)
            $('#' + field).val(JSON.stringify(that.Filters));
        else
            $('#' + field).val('');
        setTimeout(function () {
            if ($('.edit_organization').length > 0) {
                $('.edit_organization').submit();
            } else {
                $('.display_settings_form').submit();
            }
        }, 200);
    };

    const manage_form_banner_visibility = function (that) {
        if ($(that).val() == 'banner_image') {
            $('.banner-resource-slider').addClass('d-none');
            $('.banner-image').removeClass('d-none');
            $('.card_image').removeClass('d-none');
        } else {
            $('.banner-resource-slider').removeClass('d-none');
            $('.banner-image').addClass('d-none');
            $('.card_image').addClass('d-none');
        }
    };

    const manage_form_banner_title_visibility = function (that) {
        if ($(that).val() == 'banner_title_image') {
            $('.banner-title-text').addClass('d-none');
            $('.banner-title-image').removeClass('d-none');
        } else {
            $('.banner-title-text').removeClass('d-none');
            $('.banner-title-image').addClass('d-none');
        }
    };

}