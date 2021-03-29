/**
 * Events Tracker Management
 *
 * @author Furqan Wasi <furqan@weareavp.com>
 *
 * @param track_params
 *
 * @constructor
 */
function EventsTracker(track_params) {

    let that = this;
    this.track_params = track_params;
    this.app_helper = new App();
    this.views_track = {};
    this.tracking_updating_status = false;
    this.rules_tracking_log = {
        collection_resource: {can_repeat: false},
        collection_resource_file: {can_repeat: false},
        collection_resource_file_play: {can_repeat: true},
        index: {can_repeat: false},
        transcript: {can_repeat: false}
    };

    this.handlecallback = function (response, container, requestData) {
        try {
            eval('this.' + requestData.action + '(response,container,requestData)');
        } catch (err) {
            console.log(err);
        }
    };

    this.record_tracking = function (response, container) {
        that.tracking_updating_status = false
    };
    const record_hit = function () {
        let data = {
            action: 'record_tracking',
            information: that.views_track,
            request_type: 'add',
        };
        if (that.tracking_updating_status == false) {
            setTimeout(function () {
                that.tracking_updating_status = true;
                that.app_helper.classAction($('#record_tracking_path').attr('href'), data, 'JSON', 'GET', '', that, false);
            }, 1500);
        } else {
            setTimeout(function () {
                that.app_helper.classAction($('#record_tracking_path').attr('href'), data, 'JSON', 'GET', '', that, false);
            }, 4000);
        }


    };

    /**
     *
     * @param type
     * @param target_id
     */
    this.track_hit = function (type, target_id_raw, by_pass_and_record) {
        if(typeof by_pass_and_record == 'undefined'){
            by_pass_and_record = false;
        }
        let target_id = target_id_raw.toString();
        let current_params = that.track_params;
        current_params.target_id = target_id;
        if (typeof type != 'undefined' && ($.inArray(target_id, that.views_track[type]) == -1 || this.rules_tracking_log[type]['can_repeat'] == true || by_pass_and_record == true)) {
            ahoy.track(type, current_params);
            if (typeof that.views_track[type] == 'undefined')
                that.views_track[type] = [];
            that.views_track[type].push(target_id);
            record_hit();
        }
    };

    /**
     *
     * @param tabType
     */
    this.track_tab_hits = function (tabType, by_pass_and_record) {
        if ($('#file_' + tabType + '_select').length > 0) {
            let index_transc = $('#file_' + tabType + '_select').selectize();
            let selectize = index_transc[0].selectize;
            that.track_hit(tabType, selectize.getValue(), by_pass_and_record);
        }
    };

    /**
     *
     * @param type
     * @param keyword
     *
     * @returns {boolean}
     */
    this.check_keyword_already_tracked = function (type, keyword) {
        keyword = keyword.trim();
        var search_value = Cookies.get(type);
        if (typeof search_value !== 'undefined') {
            search_value = JSON.parse(search_value);
        } else {
            search_value = [];
        }
        if (!search_value.includes(keyword)) {
            search_value.push(keyword);
            Cookies.set(type, search_value, {expires: 0.0034});
            return true;
        }
        return false
    }
}