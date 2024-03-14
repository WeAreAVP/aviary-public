// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery3
//= require rails-ujs
//= require jquery


//= require popper.min
//= require rails.validations
//= require jquery_ujs
//= require tinymce
//= require jquery-fileupload/vendor/jquery.ui.widget
//= require jquery-fileupload/jquery.iframe-transport
//= require jquery-fileupload/jquery.fileupload
//= require datatables
//= require cocoon
//= require bootstrap-tagsinput
//= require best_in_place
//= require jquery.minicolors
//= require owl.carousel.min
//= require moment
//= require daterangepicker
//= require clipboard
//= require ahoy
//= require aviary_app
//= require resource_bulk_edit
//= require jquery-ui
//= require mediaelement-and-player.min
//= require video
//= require cast_sender
//= require bootstrap-tokenfield
//= require jquery.mask
//= require_tree .

var isIE = /*@cc_on!@*/false || !!document.documentMode;
var player_widget = null;
var playerSpecificTimePlay = 0;
var activeCollapsedLayout = false;
var reloadTime = 2 * 60 * 1000; // action * second * millisecond
var lengthMenuValues = [[10, 25, 50, 100], [10, 25, 50, 100]];   // datatable row length values
var pageLength = 25;
var allowedParams = ['keywords[]', 'selected_transcript', 'selected_index','embed','t','e','auto_play','media_player','media',
    'access','offset'];
Object.size = function (obj) {
    var size = 0, key;
    for (key in obj) {
        if (obj.hasOwnProperty(key)) size++;
    }
    return size;
};
if (typeof Array.prototype.forEach != 'function') {
    Array.prototype.forEach = function (callback) {
        for (var i = 0; i < this.length; i++) {
            callback.apply(this, [this[i], i, this]);
        }
    };
}

if (window.NodeList && !NodeList.prototype.forEach) {
    NodeList.prototype.forEach = Array.prototype.forEach;
}


/**
 *
 * @param identifier string tag/id/class
 * @param options hash
 * @param start_date
 */
function daterange_init(identifier, options, start_date) {
    if (typeof options == "undefined")
        options = false;

    if (typeof start_date == "undefined")
        start_date = moment();

    if (!options) {
        options = {
            startDate: start_date,
            endDate: moment(),
            showDropdowns: true,
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
        };
    }
    $(identifier).daterangepicker(options);
}

/**
 *
 * @param append_class string tag/id/class
 */
function jsloader(append_class) {
    let html = $('.loading_skeleton').html();
    $(append_class).append(html);
}

function pad(num) {
    return ("0" + num).slice(-2);
}

/**
 *
 * @param d float
 * @returns {{seconds: string, hour: string, minute: string}}
 */
function secondsToHuman(d) {
    let time = seconds_to_time(d);
    if (!isNaN(d))
        return pad(time.h) + ':' + pad(time.m) + ':' + pad(time.s);
    else
        return '';
}

function scrollTo(container, element) {
    $(container).mCustomScrollbar("scrollTo", element, {scrollInertia: 10, timeout: 1});
}

function removeImageCustom() {
    let appHandler = new App();
    document_level_binding_element('.remove_image_custom', 'click', function () {
        $('#general_modal_close_cust_success').attr('href', $(this).data('url'));
        $('#general_modal_close_cust_success').removeClass('d-none');
        appHandler.show_modal_message('Confirmation', '<strong>Are you sure you want to remove this image?</strong>', 'danger', null);
    });
}

function timePickerShare() {
    document_level_binding_element('#start_time_share, #end_time_share', 'blur', function () {
        let time = $(this).val();
        if (typeof time != 'undefined' && time != '') {
            let seconds = humanToSeconds(time);
            if (!isNaN(seconds)) {
                $(this).val(secondsToHuman(seconds));
            }
        }
    });
}


/**
 *
 * @param d float
 * @returns {{seconds: string, hour: string, minute: string}}
 */
function seconds_to_time(d) {
    d = Number(d);
    return {h: Math.floor(d / 3600), m: Math.floor(d % 3600 / 60), s: Math.floor(d % 3600 % 60)};

}

/**
 *
 * @param d float
 * @returns {{seconds: string, hour: string, minute: string}}
 */
function secondsToHumanHash(d) {
    let time = seconds_to_time(d);
    if (!isNaN(d))
        return {seconds: pad(time.s), minute: pad(time.m), hour: pad(time.h)};
    else
        return {seconds: pad(0), minute: pad(0), hour: pad(0)};
}

/**
 *
 * @param time string 00:00:00
 * @returns {number}
 */
function humanToSeconds(time) {
    let a = time.split(':'); // split it at the colons
    // minutes are worth 60 seconds. Hours are worth 60 minutes.
    let seconds = (+a[0]) * 60 * 60 + (+a[1]) * 60 + (+a[2]);
    return seconds;
}


/**
 *
 * @param target_element  tag/class/id
 * @param caller object
 * @param callback string
 */
function init_sortable(target_element, caller, callback) {
    $(target_element).sortable({
        activate: function (event, ui) {
            let data = $(this).sortable('toArray');
            eval('caller.callback(data)');
        },
        update: function (event, ui) {
            let data = $(this).sortable('toArray');
            eval('caller.callback(data)');
        }
    }).disableSelection();
}


/**
 *
 * @param target_element tag/class/id
 * @param time int/float
 */
function scroll_to(target_element, time) {
    if ($(target_element).length > 0) {
        $([document.documentElement, document.body]).animate({
            scrollTop: $(target_element).offset().top
        }, time);
    }
}

function fixTable() {
    $('.hidden_focus_btn').focus(function(){
        $('a[data-id="'+$(this).data('id')+'"]').last().addClass('focus');
    });
    $('.hidden_focus_btn').focusout(function(){
        $('a[data-id="'+$(this).data('id')+'"]').last().removeClass('focus');
    });
    setTimeout(function () {
        $(".DTFC_RightBodyLiner table a").each(function (i) { $(this).attr('tabindex', i + 1); });
    }, 500);
}

/**
 *
 * @param type string danger/success
 * @param text string
 */
function jsMessages(type, text) {
    html = '<div id="alert_message" class="alert animated fadeInDown alert-' + type + '">' +
    '<div id="alert">' + 
    '<span role="alert" aria-live="polite" aria-atomic="true">' + 
        '<button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>' +
        text + '</span></div></div>';
    $('body').append(html);
    window.setTimeout(function () {
        $("#alert_message").fadeIn(1500, function () {
            $(this).addClass("backToTop");
        });
    }, 10000);
}

/**
 *
 * @param value string
 * @param search_type string
 * @returns {string}
 */
function manage_field_value(value, search_type) {
    if (search_type == 'advance')
        value = value.replace(/[*]/g, '');
    value = value.replace(/[[]/g, '');
    return value;
};


/**
 *
 * @param element string tag/id/class
 * @param refresh_slider boolean
 * @param configuration hash
 */
function show_slider(element, refresh_slider, configuration) {
    if (typeof configuration == 'undefined') {
        configuration = {
            loop: true,
            margin: 0,
            autoplayHoverPause: true,
            navigation: true,
            autoplay: false,
            items: 1,
            dots: false,
            nav: true,
            singleItem: true
        };
    }
    if (typeof refresh_slider == 'undefined') {
        refresh_slider = false;
    }

    let owl_obj = $('.org-banner-slider').owlCarousel(configuration);
    if (refresh_slider) {
        $('#menu-bar').click(function () {
            owl_obj.trigger('refresh.owl.carousel');
        });
    }

    var owl = $(element).data('owl.carousel');
    if (owl) {
        owl.onResize();
    }
    $(".owl-prev").html('<i class="fa fa-chevron-left"></i>');
    $(".owl-next").html('<i class="fa fa-chevron-right"></i>');
}


function readURL(input, id) {
    if (input.files && input.files[0]) {

        if ((/\.(gif|jpg|jpeg|png)$/i).test(input.files[0].name) || ((/\.(ico)$/i).test(input.files[0].name) && id == "favicon")) {
            var reader = new FileReader();
            reader.onload = function (e) {
                $('#' + id).attr('src', e.target.result);
            };
            reader.readAsDataURL(input.files[0]);
        } else {
            alert("Invalid Image File.");
        }
    }
}


/**
 *
 * @param selector string tag/id/class
 * @param type_of_event click/keyup/etc...
 * @param func function()
 * @param unbind boolean
 */
function bindingElement(selector, type_of_event, func, unbind) {
    if (typeof unbind == 'undefined') {
        unbind = true;
    }
    if (unbind) {
        $(selector).unbind(type_of_event);
    }
    $(selector).bind(type_of_event, func);
}

/**
 *
 * @param selector string tag/id/class
 * @param type_of_event click/keyup/etc...
 * @param func function()
 * @param unbind boolean
 */
function document_level_binding_element(selector, type_of_event, func, unbind) {
    if (typeof unbind == 'undefined') {
        unbind = true;
    }
    if (unbind) {
        $(selector).unbind(type_of_event);
    }
    $(document).on(type_of_event, selector, func);
}

/**
 *
 * @param selector string tag/id/class
 * @param custom_config hash
 * @returns {*}
 */
function init_tinymce_for_element(selector, custom_config) {
    if (typeof custom_config == 'undefined') {
        custom_config = false;
    }
    if (custom_config == false) {
        height = parseInt($(selector).attr('height'), 10);
        tinyMCE.init({
            selector: selector,
            height: height,
            plugins: 'link charmap hr anchor wordcount code lists advlist',
            toolbar: "undo redo | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | forecolor backcolor",
            branding: false
        });
    } else {
        tinyMCE.init(custom_config);
    }
    return tinyMCE;
}


function selectizeInit(element){
    return $(element).not('.dataTables_length select, .dont-apply-selectize').selectize({
        openOnFocus: false,
        onInitialize: function () {
            var that = this;
            this.$control.on("click", function () {
                that.ignoreFocusOpen = true;
                setTimeout(function () {
                    that.ignoreFocusOpen = false;
                }, 50);
            });
        },
        onFocus: function () {
            if (!this.ignoreFocusOpen) {
                this.open();
            }
        }
    });
}


document.addEventListener("DOMContentLoaded", function (event) {
    init_tinymce_for_element('.apply_tinymce_to_it');

    $('.search_field_selector_main').on('keyup', function () {
        $(this).parent('.search-query-form').find('.keywords_main').val($(this).val());
    });

});

function resourceSearchBar() {
    if ($(".search_details_bar > div").length > 0) {
        $(".search_details_bar > div").unstick();
        if ($(window).width() >= 992) {
            let top = $('#header').length > 0 ? 40 : 0;
            $(".search_details_bar > div").sticky({topSpacing: top, responsiveWidth: true});
        } else {
            $(".search_details_bar > div").sticky({topSpacing: 0, responsiveWidth: true});
        }
        $(".search_details_bar > div").sticky('update');
    }
}

function checkMenuType(layout) {
    activeCollapsedLayout = $('#main_container').hasClass('main_collapsed');
    subNavs = ['#permission_subnav', '#integration_nav', '#analytics_subnav', '#organization_subnav','#ohms_nav'];
    if (layout == 'main_collapsed') {
        for (subnav in subNavs) {
            if ($(subNavs[subnav]).hasClass('show')) {
                $(subNavs[subnav]).removeClass('show');
                $(subNavs[subnav]).addClass('collapsed');
            }
        }

        $('[data-toggle="tooltip"]').tooltip({
            template: '<div class="tooltip sidebartooltip"><div class="arrow"></div><div class="tooltip-inner"></div></div>'
        });
    } else {
        for (subnav in subNavs) {
            if ($(subNavs[subnav]).hasClass('collapsed')) {
                $(subNavs[subnav]).removeClass('collapsed');
                $(subNavs[subnav]).addClass('show');
            }
        }
        $('[data-toggle="tooltip"]').tooltip('dispose');
    }

}

function mobileLayoutEvents() {
    $("#close-button").click(function () {
        $("#sidebar-main").addClass('main_collapsed').removeClass('not-collapsed');
    });
}

$(document).on('turbolinks:load', function () {
    $('select').not('.dataTables_length select, .dont-apply-selectize').selectize();
    $(".transcript-dl").mCustomScrollbar();
});

$(window).resize(function () {
    if ($('#sidebar-main').length > 0) {
        if ($(window).width() < 1024) {
            $('#sidebar-main').addClass('main_collapsed').removeClass('not-collapsed');
            $(".main-content").removeClass('open');
        } else if ($(window).width() > 1024 && activeCollapsedLayout) {
            $('#sidebar-main').removeClass('main_collapsed').addClass('not-collapsed');
            $(".main-content").addClass('open');
        } else {
            $('#sidebar-main').removeClass('main_collapsed').addClass('not-collapsed');
            $(".main-content").addClass('open');
        }
    }

});

$(window).on('load', function() {
    if ($(window).width() <= 992) {
        $('#sidebar-main').addClass('main_collapsed').removeClass('not-collapsed');
        $(".main-content").removeClass('open');
    }
});

$(window).resize(function () {

    if ($(window).width() >= 992) {
        $("#sub_nav").unstick();
        $("#sub_nav").sticky({topSpacing: 0});
    } else {
        $("#sub_nav").unstick();
    }
    resourceSearchBar();

});


$(document).on('keyup', '.media-duration', function (event) {
    var time = $(this).val();
    var seconds = humanToSeconds(time);

    if (isNaN(seconds)) {
        $(this).val('00:00:00');
        $(this).next().val(0);
    } else {
        $(this).next().val(seconds);
    }
});

$(document).on('keyup', '.only_allow_number', function (event) {
    var reg = /^\d+$/;
    if ($(this).val() < 0 || !$(this).val().match(reg)) {
        $(this).val(0);
    }
});

function initToolTip(element){
    if (typeof element != 'undefined' && element)
        $(element).tooltip();
    else
        $('[data-toggle="tooltip"]').tooltip();
}

function initTooltipAccessibility() {
    $('button.info-btn').each(function () {
        if ($(this).data('content') !== '') {
            $(this).tooltip();
            $(this).attr('aria-label', $(this).data('content'));
        }
    });
}

function skip_to_content(){

    document_level_binding_element('.skiptocontent', 'keyup', function (event) {
        if (event.keyCode === 13 || event.keyCode === 32) {
            if ($('.vjs-big-play-button').length && !$('.vjs-has-started').length)
                $('.vjs-big-play-button').focus();
            else if ($('.vjs-play-control'))
                $('.vjs-play-control').focus();
            else
                $('.focusable:first').focus();
        }
    });
}

$(function () {
    skip_to_content();
    setTimeout(function () {
        $('[data-toggle="tooltip"]').tooltip({
            trigger: 'hover'
        });
    }, 1000);
    if ($('#sidebar-main').length == 0) {
        $(".main-content").removeClass('open');
    }
    $('.search-nav .form-control').click(function () {
        $('.buttons-search').show();
        $(this).addClass("advanced-search-on");
        $('.keyboard_virtual_custom').addClass('mt-30px');
        $('.keyboard_virtual_custom').removeClass('mt-1');
    });

    $(document).click(function (e) {
        if (!$(e.target).hasClass('form-control')) {
            $(".search-nav .form-control").removeClass("advanced-search-on");
            $('.buttons-search').hide();
        }
    })


    $('.search-nav .form-control').blur(function () {
        setTimeout(function () {
            let flagHide = true;
            if ($('#transliteration').length > 0 && $('#transliteration').prop('checked')) {
                flagHide = false;
            }

            if (flagHide) {
                setTimeout(function () {
                    $('.keyboard_virtual_custom').addClass('mt-1');
                    $('.keyboard_virtual_custom').removeClass('mt-30px');
                }, 500);
            }

        }, 500);

    });


    if ($(window).width() >= 767) {
        $("#sub_nav").sticky({topSpacing: 0});
    }

    $('#introModal').on('shown.bs.modal', function () {
        var playPromise = document.getElementById('intro_video').play();
        if (playPromise !== undefined) {
            playPromise.then(function () {
            }).catch(function (error) {
            });
        }
    });

    $('#introModal').on('hidden.bs.modal', function () {
        $('#intro_video')[0].pause();
    });

    if ($('#password_help_edit').length > 0) {
        setTimeout("$('#password_help_edit').tooltip()", 500);
    }
    $('#signupmodal').on('shown.bs.modal', function () {
        $('#password_help').tooltip();
    });
    $('select').not('.dataTables_length select, .dont-apply-selectize').selectize();
    $('.sign_up_link').click(function (e) {
        $('#signinmodal').modal('hide');
        $('#access_denied_popup').modal('hide');
        setTimeout(function () {
            $('#signupmodal').modal('show');
        }, 500);
    });
    checkMenuType($('#menu-bar').data('layout'));
    mobileLayoutEvents();
    if ($(".organization-blur").length > 0) {
        $(".organization-blur").blur(function () {
            var value = $(this).val();
            var currentSubdomain = $("#organization_url").val();
            var newString = value.replace(/&/ig, "and").toLowerCase();
            newString = newString.replace(/[^A-Z0-9]+/ig, "").toLowerCase();
            if ($.trim(currentSubdomain) == "") {
                $('#organization_url').val(newString);
            }
        });
    }
    function toggleMenu()
    {
        if($('#sidebar-main').hasClass("not-collapsed"))
        {
            $('#sub_nav').find('nav').attr("aria-expanded","true");
        }
        else
        {
            $('#sub_nav').find('nav').attr("aria-expanded","false");
        }
    }
    if ($('#menu-bar').length > 0) {
        toggleMenu();
        $('#menu-bar').click(function () {
            let url = $(this).data('url');
            $('#sidebar-main').toggleClass('main_collapsed');
            $('#sidebar-main').toggleClass('not-collapsed');
            $('.main-content').toggleClass('open');
            layout = $('#sidebar-main').hasClass('main_collapsed') ? 'main_collapsed' : 'not-collapsed';
            checkMenuType(layout);
            toggleMenu();
            $.ajax({
                url: url,
                data: {layout: layout},
                type: 'POST',
                dataType: 'json',
                success: function (response) {
                }
            });
        });
    }
    if ($('#admin_notice_select_all').length > 0) {
        $('#admin_notice_select_all').click(function () {
            let users = $('#notification_list').selectize();
            let selectize = users[0].selectize;
            selectize.setValue(Object.keys(selectize.options));
        });
    }
    resourceSearchBar();
    linkToExternalTab();
    initTooltipAccessibility();
});

function dateTimePicker(objectCaller, element, drops) {
    $(element).daterangepicker({
        timePicker: true,
        drops: drops,
        opens: 'right',
        showDropdowns: true,
        minDate: moment().subtract(7, 'days'),
        maxDate: moment().add(10, 'Y'),
        minYear: parseInt(moment().year(), 10),
        maxYear: parseInt(moment().add(10, 'Y').year(), 10),
        alwaysShowCalendars: true,
        timePicker24Hour: true,
        locale: {
            format: 'MM-DD-YYYY HH:mm'
        },
        ranges: {
            'This Week': [moment(), moment().endOf("week")],
            'One Week From Now': [moment(), moment().add(7, 'days')],
            'Next Week': [moment().add(1, 'week').startOf('week'), moment().add(1, 'week').endOf('week')],
            'This Month': [moment().startOf('month'), moment().endOf('month')],
            'One Month From Now': [moment(), moment().add(1, 'M')],
            'Next Month': [moment().add(1, 'M').startOf('month'), moment().add(1, 'M').endOf('month')],
            'This Year': [moment(), moment().endOf("year")],
            'One Year From Now': [moment(), moment().add(1, 'Y')],
        }
    });

}

const clearKeyWords = function (keyword) {
    keyword = keyword.replace(/[\/\\()|'"*:^~`{}]/g, '');
    keyword = keyword.replace(/]/g, '');
    keyword = keyword.replace(/[[]/g, '');
    keyword = keyword.replace(/[{}]/g, '');
    return keyword;
}

function startTimeCheckbox(update_url, currentTime) {
    $('.start_time_checkbox').click(function () {
        if (update_url)
            checkAndCreateUrl();
        if ($(this).prop("checked") === true) {
            if ($('#start_time_share').val() == '')
                $('#start_time_share').val(secondsToHuman(currentTime));
            $('.video-start-time').removeAttr('disabled');

        } else {
            $('.video-start-time').attr('disabled', 'disabled');
            $('#share_link').val();
        }
    });
}

const getSearchKeywordsAsString = function () {
    let keywords = $('.search_field_selector_single').val();
    if (typeof keywords == 'undefined') {
        keywords = $('.search_field_selector_main').val();
    }

    if ($('.advance_option_search').hasClass('d-none')) {
        keywords = '';
        $.each($('.search_field_selector'), function (index, obj) {
            keywords += $(obj).val() + ' ';
            if (!$($('select.op_selector')[index]).hasClass('add_wanted_class') && typeof $($('select.op_selector')[index]).val() != 'undefined') {
                keywords += $($('select.op_selector')[index]).val() + ' ';
            }
        });
    }
    return keywords;
}

function removeScrollMobile() {
    if ($(window).width() < 767) {
        $("*").mCustomScrollbar("destroy");
        $('.mCustomScrollbar_description').attr('style', 'height:auto!important;max-height:inherit !important;');
        $('#view_edit_media_metadata_custom').attr('style', 'height:auto!important;max-height:inherit !important;');
    }
}

function removeImageCustom() {
    let appHandler = new App();
    document_level_binding_element('.remove_image_custom', 'click', function () {
        $('#general_modal_close_cust_success').attr('href', $(this).data('url'));
        $('#general_modal_close_cust_success').removeClass('d-none');
        appHandler.show_modal_message('Confirmation', '<strong>Are you sure you want to remove this image?</strong>', 'danger', null);
    });
}

function timePickerShare() {
    document_level_binding_element('#start_time_share, #end_time_share', 'blur', function () {
        let time = $(this).val();
        if (typeof time != 'undefined' && time != '') {
            let seconds = humanToSeconds(time);
            if (!isNaN(seconds)) {
                $(this).val(secondsToHuman(seconds));
            }
        }
    });
}

const addKeywordToUrl = function (keyword) {
    let allowed = allowedParams;
    let query = 'keywords[]=' + keyword;
    querySeperator = window.location.search == '' ?  '?' : '&'
    stringParams = window.location.search + querySeperator + query;
    params = new URLSearchParams(stringParams);
    counter = 0;
    for (let p of params) {
        if (!allowed.includes(p[0])){
            params.delete(p[0]);
        }
        counter +=1;
    }
    window.location = '?' + params.toString();
}

function isUrlValid(value) {
    return /https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,4}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)$/i.test(value);
}

const linkToExternalTab = function () {
    $(document).on("click", 'a', function () {
        let a = new RegExp('/' + window.location.host + '/');
        if (!a.test(this.href) && isUrlValid(this.href) && !this.href.includes('aviaryplatform.com')) {
            $(this).attr('target', '_blank');
        }
    });
}
function setIterviewNotes(){
    if($('.notes_inner_button').length > 0)
    {
        getResponse(0);
        document_level_binding_element(".notes_inner_button", 'click', function (e) {
            getResponse(1);
        });
        $('#notesForm').attr("id","notesFormButton");
        $('#modalPopupNotes').attr("id","modalPopupNotesButton");
        document_level_binding_element("#notesFormButton", 'submit', function (e) {
            e.preventDefault();
            let form = $(this);
            let url = form.attr("action");
            let serializedData = form.serialize();
            if ($('#note').val() === "") {
                $('.error_note').html("Please type a note before clicking the Add Note button.");
            } else {
                $.ajax({
                    type: "POST",
                    url: url,
                    data: serializedData,
                    success: function (response) {
                        $('#note').val("");
                        $('.errors').html("");
                        setNoteResponse(response);
                        jsMessages('success', 'Note added successfully.');
                        if (response.color){
                            setNoteColor(response.color)
                        }
                        $('#modalPopupNotesButton').modal('hide');
                    },
                    error: function (response, status, error) {
                        let info = jQuery.parseJSON(response.responseText);
                        for (const property in info.errors) {
                            $('.error_' + property).html(property.toUpperCase() + ' ' + info.errors[property]);
                        }
                    }
                });
            }
        })

        document_level_binding_element(".notes_status_btn", 'click', function (e) {
            let formData = {
                'note_id': e.target.getAttribute("data-id"),
                'status': e.target.getAttribute("data-status")
            };
            $.ajax({
                url: e.target.getAttribute("data-url"),
                data: formData,
                type: 'POST',
                dataType: 'json',
                success: function (response) {
                    if (response.color){
                        setNoteColor(response.color)
                    }
                },
            });
            jsMessages('success', 'Note updated successfully.');
        });
    }
}

function setNoteResponse(response){
    let html = ""
    let index = 1;
    response.data.forEach(element => {
        html = html + '<div>Note '+index+': ' + element.note + '</div>';
        html = html + '<div class="d-flex mb-3"><div class="custom-checkbox mr-3"><input type="radio" class="unresolve notes_status_btn" name="status_' + element.id + '" id="unresolve_' + element.id + '" value="0" ' + (element.status ? "" : 'checked="checked"') + ' data-id="' + element.id + '" data-interview_id="' + element.interview_id + '" data-status="0" data-url="' + $('.notes_inner_button').attr("data-updateurl") + '" ></input><label for="unresolve_' + element.id + '">Unresolved</label></div>';
        html = html + '<div class="custom-checkbox mr-3"><input type="radio" class="resolve notes_status_btn" name="status_' + element.id + '" id="resolve_' + element.id + '" value="1" ' + (element.status ? 'checked="checked"' : "") + ' data-id="' + element.id + '" data-interview_id="' + element.interview_id + '" data-status="1" data-url="' + $('.notes_inner_button').attr("data-updateurl") + '" ></input><label for="resolve_' + element.id + '">Resolved</label></div></div>';
        index = index + 1;
    });
    html = (response.length === 0 ? "There are currently no notes associated with this interview." : html);
    $('#listNotes').html(html);

}

function setNoteColor(color){
    $('.notes_inner_button').removeClass('text-secondary');
    $('.notes_inner_button').removeClass('text-danger');
    $('.notes_inner_button').removeClass('text-success');
    $('.notes_inner_button').addClass(color);
}

function getResponse(opt)
{
    if(opt === 1)
    {
        $("#notesFormButton").attr("action", $('.notes_inner_button').attr("data-url"));
        $("#notesFormButton").attr("data-id", $('.notes_inner_button').attr("data-id"));
    }
    $.ajax({
        url: $('.notes_inner_button').attr("data-url"),
        type: 'GET',
        dataType: 'json',
        success: function (response) {
            if(response.color)
            {
                setNoteColor(response.color)
            }
            setNoteResponse(response);
            if(opt === 1)
            {
                $('#note').val("");
                $('#modalPopupNotesButton').modal('show');
            }
        },
    });
}

function manageTable()
{
    $('.ui-sortable li a').focus(function() {
        $(this).addClass("ui-selecting");
    }); 
    $('.ui-sortable li a').focusout(function() {
        $(this).removeClass("ui-selecting");
    });
    $('.ui-sortable li a').bind('keydown', function(event) {
        if(event.which == 40 && event.shiftKey)
        {
            moveDown($(this).parent())
            $(this).focus();
        }
        if(event.which == 38 && event.shiftKey)
        {
            moveUp($(this).parent())
            $(this).focus();
        }
    });
}

function moveUp($item) {
    $before = $item.prev();
    $item.insertBefore($before);
}

function moveDown($item) {
    $after = $item.next();
    $item.insertAfter($after);
}
