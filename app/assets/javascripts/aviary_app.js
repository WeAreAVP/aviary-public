/**
 * App operations
 *
 * @author Furqan Wasi<furqan@weareavp.com, furqan.wasi66@gmail.com>
 *
 * Apps  Handler
 *
 *
 * @returns {App}
 *
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 */
var selfApp;

function App() {
    selfApp = this;
    /**
     *
     * @returns {object}
     */
    this.getDefaultData = function () {
        return selfApp.defaultData;
    };

    /**
     * Class Action
     *
     * @param {string} url
     * @param {object} requestData
     * @param {string} responseType
     * @param {string} requestType
     * @param (string )containerToBeaffected
     * @param {object} caller
     *
     * @returns {boolean}
     */
    this.classAction = function (url, requestData, responseType, requestType, containerToBeaffected, caller, show_loader) {
        if (typeof show_loader == 'undefined') {
            show_loader = true;
        }

        if (show_loader) {
            selfApp.show_loader();
            selfApp.show_loader_text();
        }
        let object_ajax = $.ajax({
            url: url,
            data: requestData,
            error: function (response) {
                console.log(requestData.action + ':: Problem ' + requestData);
                selfApp.actionBasedMethodExc(response, containerToBeaffected, caller, requestData);
                selfApp.hide_loader();
            },
            dataType: responseType,
            success: function (response) {
                if (show_loader) {
                    selfApp.hide_loader();
                }
                selfApp.actionBasedMethodExc(response, containerToBeaffected, caller, requestData);
            },
            type: requestType
        });
        return object_ajax;
    };

    /**
     *
     * @param {object} defaultData
     *
     * @returns {none}
     */
    this.setDefaultData = function (defaultData) {
        selfApp.defaultData = defaultData;
    };


    /**
     *
     * @returns {none}
     */
    this.show_loader = function () {
        $('.loadingCus').show();
        this.show_loader_text();

    };

    /**
     *
     * @returns {none}
     */
    this.hide_loader = function () {
        $('.loadingCus').hide();
        this.hide_loader_text();
    }
    ;


    this.email_validator = function (email) {
        var regex = /^([a-zA-Z0-9_.+-])+\@(([a-zA-Z0-9-])+\.)+([a-zA-Z0-9]{2,4})+$/;
        return regex.test(email);
    };

    /**
     * What type of object is this.
     *
     * @param {json} object
     *
     * @returns {String}
     */
    this.whatIsIt = function (object) {
        var stringConstructor = "test".constructor;
        var arrayConstructor = [].constructor;
        var objectConstructor = {}.constructor;
        if (object === null) {
            return "null";
        } else if (object === undefined) {
            return "undefined";
        } else if (object.constructor === stringConstructor) {
            return "String";
        } else if (object.constructor === arrayConstructor) {
            return "Array";
        } else if (object.constructor === objectConstructor) {
            return "Object";
        } else {
            return "don't know";
        }
    };
    /**
     *
     * @returns {none}
     */
    this.show_loader_text = function () {
        $('.loadingtextCus').show();
    };

    /**
     * Remove Param
     * 
     * @param {string} key param to be removed
     * @param {string} sourceURL target url 
     * 
     * @returns {string}
     */
    this.removeParam = function(key, sourceURL) {
        var rtn = sourceURL.split("?")[0],




            param,
            params_arr = [],
            queryString = (sourceURL.indexOf("?") !== -1) ? sourceURL.split("?")[1] : "";
        if (queryString !== "") {
            params_arr = queryString.split("&");
            for (var i = params_arr.length - 1; i >= 0; i -= 1) {
                param = params_arr[i].split("=")[0];
                if (param === key) {
                    params_arr.splice(i, 1);
                }
            }
            rtn = rtn + "?" + params_arr.join("&");
        }
        return rtn;
    }

    /**
     *
     * @returns {none}
     */
    this.hide_loader_text = function () {
        $('.loadingtextCus').text('');
        $('.loadingtextCus').hide();
    };


    /**
     *
     * @param {sting} heading
     * @param {sting} message
     * @param {sting} type
     */
    this.show_modal_message = function (heading, message, type, script) {
        if (type == 'danger') {
            message = '<span class="text-danger"> ' + message + ' </span>';
        } else if (type == 'info') {
            message = '<span > ' + message + ' </span>';
        } else {
            message = '<span class="text-success"> ' + message + '</span>';
        }
        $('#general_modal_title_cust').html('<strong><center>' + heading + '</center></strong>');
        $('.general_modal_body_cust').html('<b><center>' + message + '</center></b>');
        if (typeof script != 'undefined' && script != '') {
            $('#general_modal_close_cust').attr('onclick', script);
        } else {
            $('#general_modal_close_cust').attr('onclick', 'void(0)');
        }
        $('#general_modal_message_cust').modal('show');

    };


    /**
     * A utility function to find all URLs - FTP, HTTP(S) and Email - in a text string
     * and return them in an array.  Note, the URLs returned are exactly as found in the text.
     *
     * @param text
     *            the text to be searched.
     * @return an array of URLs.
     */
    this.findUrls = function (text) {
        var source = (text || '').toString();
        var urlArray = [];
        var url;
        var matchArray;

        // Regular expression to find FTP, HTTP(S) and email URLs.
        var regexToken = /(((ftp|https?):\/\/)[\-\w@:%_\+.~#?,&\/\/=]+)|((mailto:)?[_.\w-]+@([\w][\w\-]+\.)+[a-zA-Z]{2,3})/g;

        // Iterate through any URLs in the text.
        while ((matchArray = regexToken.exec(source)) !== null) {
            var token = matchArray[0];
            urlArray.push(token);
        }

        return urlArray;
    };

    this.getUrlParameter = function (url) {
        var params = {};
        var parser = document.createElement('a');
        parser.href = url;
        let url_raw = url.split('?');
        var query = parser.search.substring(1);
        var vars = query.split('&');

        for (var i = 0; i < vars.length; i++) {
            var pair = vars[i].split('=');
            if (pair[0]) {
                params[pair[0]] = decodeURIComponent(pair[1]);
            }
        }
        return [params, url_raw[0]];
    };
    /**
     *
     * @param url
     * @returns {[[], *|string]}
     */
    this.getUrlParamRepeatable = function (url){
        var params = [];
        var parser = document.createElement('a');
        parser.href = url;
        let url_raw = url.split('?');
        var query = parser.search.substring(1);
        var vars = query.split('&');

        for (var i = 0; i < vars.length; i++) {
            var pair = vars[i].split('=');
            if (pair[0]) {
                params.push(pair[0]+'='+decodeURIComponent(pair[1]));
            }
        }
        return [params, url_raw[0]];
    };

    /**
     *
     * @param response
     * @param container
     * @param requestData
     */
    this.handlecallback = function (response, container, requestData) {
        var functionName = requestData.action;
        try {
            eval('selfApp.' + functionName + '(response,container)');
        } catch (err) {
            console.log('class error', err);
            try {
                this.callback_child(response, container, requestData);
            } catch (err) {
                console.log('class error', err);
            }
        }
    };

    /**
     * Action Based Method Exc.
     *
     * @param {string} action
     * @param {string} response
     * @param {string} container
     * @param {string} caller
     *
     * @returns {none}
     */
    this.actionBasedMethodExc = function (response, container, caller, requestData) {
        try {
            caller.handlecallback(response, container, requestData, caller);
        } catch (err) {
            console.log('class error', err, caller);
        }

    };

    this.serverSideDatatable = function (element, caller, config, ajax_url) {

        if (!config || typeof config == 'undefined' ) {
            config = {
                responsive: true,
                processing: true,
                serverSide: true,
                pageLength: 10,
                bInfo: true,
                destroy: true,
                bLengthChange: false,
                scrollX: true,
                scrollCollapse: false,
                pagingType: 'simple_numbers',
                'dom': "<'row'<'col-md-6'f><'col-md-6'p>>" +
                    "<'row'<'col-md-12'tr>>" +
                    "<'row'<'col-md-5'i><'col-md-7'p>>",
                language: {
                    info: 'Showing _START_ - _END_ of _TOTAL_',
                    infoFiltered: '',
                    zeroRecords: 'No Records found.',
                },
                ajax: {
                    url: ajax_url,
                    type: 'POST'
                },
                columnDefs: [
                    {orderable: false, targets: -1}
                ],
                initComplete: function (settings) {
                    try {
                        caller.datatableInitComplete(settings);
                    } catch (e) {

                    }

                }
            }
        };

        let dataTableElement = $(element);
        if (dataTableElement.length > 0) {
            this.dataTableObj = dataTableElement.DataTable(config);
        }
    }

}


