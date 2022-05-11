/**
 * Saved Searches Handler
 *
 * @author Usman Javaid <usman@weareavp.com>
 *
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 *
 */

function SavedSearches() {

    let appHelper = new App();
    let that = this;

    this.initialize = function () {
        appHelper.serverSideDatatable('#saved_searches_table', that, '', $('#saved_searches_table').data('url'));
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
}