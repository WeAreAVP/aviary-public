/**
 * Markers Common
 *
 * @author Furqan Wasi<furqan@weareavp.com>
 *
 */


function MarkersCommon() {

    this.page_manager = function (information, total_page) {
        let page_number_index = information[2];
        if (page_number_index <= 0) {
            page_number_index = 1;
        }
        if (page_number_index >= total_page) {
            page_number_index = total_page - 1;
        }
        return page_number_index;
    }

    this.current_index_update = function (currentIndex, is_next_button, last_button_action) {
        let currentIndexCustom = currentIndex;
        if (last_button_action == 'next' && !is_next_button) {
            currentIndexCustom += -2
        } else if (last_button_action == 'back' && is_next_button) {
            currentIndexCustom += +2
        }
        return currentIndexCustom;
    }

    this.set_count_update = function (count, effected_element, element, parent_element) {
        if (count < 0)
            count = 1;
        $(element).parents(parent_element).find(effected_element).text(count);
    }
    this.update_last_action = function (is_next_button) {
        let last_button_action = 'back';
        if (is_next_button) {
            last_button_action = 'next';
        }
        return last_button_action;
    }
    this.transcript_hits_information = function (collection_resource) {
        let total_page = collection_resource.transcripts.current_selected_total_page('transcript', collection_resource.transcripts.selected_transcript, false);
        let all_hits = collection_resource.transcript_hits_count[collection_resource.selected_transcript];
        return {total_page: total_page, all_hits: all_hits};
    }
}
