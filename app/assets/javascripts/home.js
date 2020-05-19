$(function () {
    window.enablePopup = function () {
        $('.show_hide_description').on('click', function () {
            $('.list-collection-info').html($('.' + $(this).data('id')).html());
            $('.collection-org-logo').attr('src', $(this).data('org-logo'));
            $('.collection_collection_title').html($(this).data('collection-title'));
            $('.collection_image_holder').attr('style', $(this).data('collection-img'));
            $('.collection_org_title').html($(this).data('org-title'));
            $('.collection_search_collection').text('Browse ' + $(this).data('type') + ' >>');
            $('.collection_search_collection').attr('href', $(this).data('collection-search'));
            $('.collection_collection_title').attr('href', $(this).data('collection-path'));
            $('#detailDisplayModal').modal('show');
        });
    };
    window.setCarousel = function () {
        var $carouselElements, msViewportStyle;
        if (navigator.userAgent.match(/IEMobile\/10\.0/)) {
            msViewportStyle = document.createElement('style');
            msViewportStyle.appendChild(document.createTextNode('@-ms-viewport{width:auto!important}'));
            document.querySelector('head').appendChild(msViewportStyle);
        }
        $carouselElements = [".home-featured-resources.owl-carousel", ".home-featured-collections.owl-carousel", ".home-featured-organizations.owl-carousel"];
        return $carouselElements.forEach(function (value) {
            return $(value).owlCarousel({
                loop: false,
                margin: 20,
                responsive: {
                    0: {
                        items: 1
                    },
                    480: {
                        items: 2
                    },
                    768: {
                        items: 3
                    },
                    1024: {
                        items: 4
                    }
                },
                items: 4,
                nav: true
            });
        });
    };


    window.getData = function (path, _obj) {
        return $.ajax({
            type: 'GET',
            url: path,
            success(data) {
                $('.loader').hide();
                $('#' + _obj).html(data.partial);
                if ($('#playlists_home').length > 0) {
                    if ($('#playlists_home').html().includes('playlist_home_cont')) {
                        $('.playlist_tab_clickable').removeClass('d-none');
                    }
                }
                setCarousel();
                return enablePopup();
            },
            beforeSend() {
                return jsloader('#' + _obj);
            },
            error(xhr) {
                var er;
                er = JSON.parse(xhr.responseText);
                return;
            }
        });
    };

    return $('.home-index-view').children().each(function () {
        var id, path;
        id = $(this).attr('id');
        path = $(this).data('path');
        return getData(path, id);
    });
});