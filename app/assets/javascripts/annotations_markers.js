/**
 * Annotations Marker
 *
 * @author Furqan Wasi<furqan@weareavp.com>
 *
 */


function AnnotationMarkers() {
    this.last_button_action_annotation = 'next';
    this.currentIndexAnnotation = 0;
    this.$prevBtnAnnotation = $(".back_button");
    this.$nextBtnAnnotation = $(".next_button_annotation");
    this.currentClass = 'active';
    this.collection_resource = {};
    let that = this;
    this.initialize = function (selected_val) {
        init_annotation_marker_button();
        that.markers_common = new MarkersCommon();
        that.switch_marker_arrows(selected_val);
    };

    this.switch_marker_arrows = function (selected_val) {
        $('.annotation_markers_button_handle').addClass('d-none');
        $('.annotation-box .annotation_markers_' + selected_val).removeClass('d-none');
    }
    const init_annotation_marker_button = function () {
        that.$nextBtnAnnotation.add(that.$prevBtnAnnotation).unbind('click');
        that.$nextBtnAnnotation.add(that.$prevBtnAnnotation).on("click", function () {
            let $current = {};
            let number = $(this).is(that.$prevBtnAnnotation) ? -1 : 1;
            let is_next_button = $(this).hasClass('next_button');
            let total_page = that.collection_resource.transcripts.current_selected_total_page('transcript', that.collection_resource.transcripts.selected_transcript, false);
            let all_hits = that.collection_resource.annotation_hits_count[that.collection_resource.selected_transcript];

            if (Object.keys(all_hits).length > 0) {
                that.currentIndexAnnotation = that.markers_common.current_index_update(that.currentIndexAnnotation, is_next_button, that.last_button_action_annotation);
                if (typeof all_hits[(that.currentIndexAnnotation)] != 'undefined') {
                    let information = all_hits[(that.currentIndexAnnotation)].split('||');
                    $current = $('#' + information[0]).find('.annotation_marker')[parseInt(information[1], 10)];
                    if ($($current).length > 0) {
                        // found and loading
                        that.jumpTo($current, total_page);
                        that.markers_common.set_count_update(that.currentIndexAnnotation + 1, '.annotation_current_count', this, '.button_handle');
                        that.currentIndexAnnotation += number

                    } else {
                        // found but not on current pages;
                        let information = all_hits[that.currentIndexAnnotation].split('||');
                        let page_number_index = that.markers_common.page_manager(information, total_page);
                        // new transcript page
                        let extra_info = {currentIndexAnnotation: that.currentIndexAnnotation};
                        that.currentIndexAnnotation += number
                    }
                } else if (that.currentIndexAnnotation > (all_hits.length - 1)) {
                    //not found loading first occurrence
                    that.currentIndexAnnotation = 0;
                    let information = all_hits[(that.currentIndexAnnotation)].split('||');
                    $current = $('#' + information[0]).find('.annotation_marker')[parseInt(information[1], 10)];
                    if ($($current).length > 0) {
                        that.jumpTo($current, total_page);
                        that.currentIndexAnnotation += number;
                        that.markers_common.set_count_update(that.currentIndexAnnotation, '.annotation_current_count', this, '.button_handle');
                    } else {
                        load_occurrence(total_page, 'first');
                        that.markers_common.set_count_update(that.currentIndexAnnotation, '.annotation_current_count', this, '.button_handle');
                    }
                } else if (that.currentIndexAnnotation < 0) {
                    // not found loading last occurrence
                    that.currentIndexAnnotation = all_hits.length - 1;
                    let information = all_hits[(that.currentIndexAnnotation)].split('||');
                    $current = $('#' + information[0]).find('.annotation_marker')[parseInt(information[1], 10)];
                    if ($($current).length > 0) {
                        that.jumpTo($current, total_page);
                        that.markers_common.set_count_update(that.currentIndexAnnotation + 1 , '.annotation_current_count', this, '.button_handle');
                        that.currentIndexAnnotation += number;
                    } else {
                        load_occurrence(total_page, 'last');
                        that.markers_common.set_count_update(that.currentIndexAnnotation, '.annotation_current_count', this, '.button_handle');
                    }
                }
                that.last_button_action_annotation = that.markers_common.update_last_action(is_next_button)
            }
        });
    }


    const load_marker = function (total_page, last_or_first) {
        let page_number_inner = false;
        let all_hits = that.collection_resource.annotation_hits_count[that.collection_resource.selected_transcript];
        let loop_all_hits = all_hits[0];
        let indexCurrent = 0;
        if (last_or_first == 'last') {
            loop_all_hits = all_hits[all_hits.length - 1];
        }

        let information = loop_all_hits.split('||');
        page_number_inner = parseInt(information[2], 10);

        return {indexCurrent: indexCurrent, page_number_inner: page_number_inner};
    };

    const load_occurrence = function (total_page, first_or_last) {
        let indexPageInfo = load_marker(total_page, first_or_last);
        let extra_info = {};
        that.collection_resource.transcripts.specific_page_load_transcript('marker_button_annotation', indexPageInfo['page_number_inner'], true, extra_info);
    };

    this.jumpTo = function ($current, total_page) {
        $(".annotation_marker").removeClass('active');
        if (total_page > 0) {
            $($current).removeClass(that.currentClass);
            if ($($current).length) {
                $($current).addClass(that.currentClass);
                try {
                    $('.transcript_point_container').mCustomScrollbar("scrollTo", '.annotation_marker.active', {scrollInertia: 200, timeout: 1});
                    $('.annotation_marker.active').click();
                } catch (e) {
                    e;
                }
            }
        }
    }

    this.update_hits_array = function () {

    };

}
