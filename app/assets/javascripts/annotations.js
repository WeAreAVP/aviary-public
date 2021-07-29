/**
 * Annotations and Annotation sets
 *
 * @author Nouman Tayyab<nouman@weareavp.com>
 *
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 *
 */

var firstTimeAnnotation = 0;
var lastAnnotationId = 0;

function Annotations() {
    var counter = 1;
    var annotationParams = {};
    const dublin_core = ['Contributor', 'Coverage', 'Creator', 'Date', 'Description', 'Format', 'Identifier', 'Language',
        'Publisher', 'Relation', 'Rights', 'Source', 'Subject', 'Type'];
    var collectionResource;
    var app_helper = new App();
    var that = this;
    var last_annotation_point = null;
    /**
     * This method is responsible for adding and editing the annotation set and its dynamic fields
     *
     */
    const annotationSetEdit = function () {
        $('.existing_dublin_core, #annotation_set_is_public').selectize();

        bindingElement('.remove_dublin_core', 'click', function () {
            $(this).parent().remove();
        });
        bindingElement('#add_dublincore', 'click', function () {
            let options = '';
            for (cnt in dublin_core) {
                options += '<option value="' + dublin_core[cnt] + '">' + dublin_core[cnt] + '</option>';
            }
            let html = '<div class="row mb-1">' +
                '<div class="col-md-4"><select name="annotation_set[dublincore_key][]" class="dublin_core_select select_' + counter + '">' + options + '</select></div>' +
                '<div class="col-md-7"><input type="text" class="string form-control" name="annotation_set[dublincore_value][]"/></div>' +
                '<a href="javascript://" class="remove_dublin_core" title="Remove Field"><i class="remove_icon_image"></i></a>' +
                '</div>';

            $('.dynamic_section_annotation_set').append(html);
            bindingElement('.remove_dublin_core', 'click', function () {
                $(this).parent().remove();
            });
            $('.select_' + counter).selectize();
            counter++;
        });
        $('#annotation_set_model form').submit(function (e) {
            e.preventDefault();
            let form = this;
            $('.error_annotation').html('');
            $(this).attr('action');
            $.ajax({
                url: $(form).attr('action') + '.json?transcript=' + $('#file_transcript_select').val(),
                data: $(form).serialize(),
                type: 'POST',
                dataType: 'json',
                success: function (response) {
                    if (Object.size(response.errors) > 0) {
                        $('.annotation_save_btn').prop("disabled", false);
                        $('.error_annotation').html('Title ' + response.errors.title);
                    } else {
                        $('#annotation_success').html(response.msg);
                        setTimeout("location.reload();", 2000);
                    }

                },

            });
        });

    };

    /**
     * Send the ajax request and load the form based on the url.
     *
     * @param url
     */
    const loadForm = function (url) {
        $('.loadingCus').show();
        $.ajax({
            url: url,
            type: 'GET',
            dataType: 'html',
            success: function (response) {
                $('#dynamic_section').html(response);
                $('.loadingCus').hide();
                annotationSetEdit();
                $('#annotation_set_model').modal();
            },

        });
    };

    /**
     * This method will enable the javascript events for the annotation sets functionality.
     *
     */
    this.initializeAnnotationSet = function (collectionObj) {
        collectionResource = collectionObj;
        $('#annotation_set_select').selectize();
        bindingElement('.add-annotation-button', 'click', function () {
            let url = $(this).data('url');
            loadForm(url);
        });
        bindingElement('.edit_annotation', 'click', function () {
            currentAnnotation = $('#annotation_set_select').val();
            let url = $(this).data('url') + '/' + currentAnnotation + '/edit';
            loadForm(url);
        });
        bindingElement('.delete_annotation', 'click', function () {
            let currentAnnotationId = $('#annotation_set_select').val();
            let currentAnnotationName = $('#annotation_set_select').text();

            $('#modalPopupBody').html('Are you sure you want to delete this annotation set? This will remove all the annotations as well.');
            $('#modalPopupTitle').html('Delete "' + currentAnnotationName + '" Annotation Set');
            $('#modalPopupFooterYes').attr('href', $(this).data('url') + '/' + currentAnnotationId);
            $('#modalPopup').modal('show');

        });
        initializeAnnotation();
        $(window).resize(function () {
            setTimeout(function () {
                adjustAnnotationSectionHeight();
            }, 1000);
        });
    };

    /**
     * The method written to the correct offset from the parent element.
     *
     * @param parentElement
     * @param currentNode
     * @returns {number|*}
     */
    const getSelectionOffsetRelativeTo = function (parentElement, currentNode) {
        var currentSelection, currentRange,
            offset = 0,
            prevSibling,
            nodeContent;

        if (!currentNode) {
            currentSelection = window.getSelection();
            currentRange = currentSelection.getRangeAt(0);
            currentNode = currentRange.startContainer;
            offset += currentRange.startOffset;
        }
        if (currentNode === parentElement) {
            return offset;
        }

        if (!parentElement.contains(currentNode)) {
            return -1;
        }

        while (prevSibling = (prevSibling || currentNode).previousSibling) {
            if (prevSibling instanceof HTMLBRElement) {
                offset += 4;
            }
            nodeContent = prevSibling.innerText || prevSibling.nodeValue || "";
            offset += nodeContent.length;
        }

        return offset + getSelectionOffsetRelativeTo(parentElement, currentNode.parentNode);

    };

    /**
     * The deleteAnnotation method manages all the events related to delete functionality
     *
     */
    const deleteAnnotation = function () {
        document_level_binding_element('.delete_text_annotation', 'click', function () {
            $('.annotation_delete_section').removeClass('d-none');
            $('.annotation-option').addClass('d-none');
            let annotationId = $('.delete_text_annotation').data('annotation');
            $('.annotation_' + annotationId).addClass('delete');
            $('.annotation-box .text-box').addClass('delete');
        });
        document_level_binding_element('.btn_delete_annotation_cancel', 'click', function () {
            $('.annotation_delete_section').addClass('d-none');
            $('.annotation-option').removeClass('d-none');
            let annotationId = $('.delete_text_annotation').data('annotation');
            $('.annotation_' + annotationId).removeClass('delete');
            $('.annotation-box .text-box').removeClass('delete');
        });
        document_level_binding_element('.btn_delete_annotation_confirm', 'click', function () {
            let annotationId = $('.delete_text_annotation').data('annotation');
            let url = $('#enter_annotation_text').data('url') + '/' + annotationId + '.json';
            $('.done_annotation').prop('disabled', true);
            let deleteCurrent = $('.annotation_' + annotationId);
            let allAnnotations = $('.annotation_marker');
            let previousObject = allAnnotations.eq(allAnnotations.index(deleteCurrent) - 1);

            let previousAnnotation = 0;
            if (previousObject.length > 0) {
                previousAnnotation = $(previousObject).data('annotation');
            }

            $.ajax({
                url: url,
                data: annotationParams,
                type: 'DELETE',
                dataType: 'json',
                success: function (response) {
                    clearSelection();
                    $('#annotation_message').html(response.msg);
                    let page_number_transcript = collectionResource.transcripts.transcript_page_number;
                    lastAnnotationId = previousAnnotation;
                    collectionResource.transcripts.specific_page_load_transcript('clear', parseInt(page_number_transcript, 10));

                    setTimeout(function () {
                        $('#annotation_message').html('');
                        var ed = tinyMCE.get('enter_annotation_text');
                        ed.setContent('');
                    }, 5000);
                },

            });
        });
    };
    /**
     * The showAnnotation method will show the annotation detail or enable/disable the annotation from the display.
     *
     */
    const showAnnotation = function () {
        document_level_binding_element('#transcript_enable_annotation', 'click', function () {
            if ($(this).prop("checked")) {
                $('.transcript_point_container').addClass('enable_annotation');
                if ($('#transcript-tab').hasClass('active') && $('.annotation_flag').length > 0) {
                    firstTimeAnnotation = 1;
                    $($('.annotation_flag')[0]).trigger('click');
                }
            } else {
                $('.annotation_flag, .annotation_marker').removeClass('active');
                $('.transcript_point_container').removeClass('enable_annotation');
            }
            $('#annotation_section').addClass('d-none');
        });
        document_level_binding_element('.annotation_flag, .annotation_marker', 'click', function () {
            if ($(this).parents('.enable_annotation').length <= 0) {
                return false;
            }
            let annotationId = $(this).data('annotation');
            $('.annotation_flag, .annotation_marker').removeClass('active');

            $('.annotation_' + annotationId).addClass('active');
            if (firstTimeAnnotation == 1 || $(".annotation_flag:hover").length > 0 || $(".annotation_marker:hover").length > 0 || $(".back_button_other:hover").length > 0 || $(".next_button_other:hover").length > 0 || $('.transcript #overlay-counters:hover').length > 0) {
                let response_hits = collectionResource.transcripts.annotation_markers.markers_common.transcript_hits_annotations(collectionResource);
                let all_hits = response_hits.all_hits;
                collectionResource.transcripts.annotation_markers.currentIndexAnnotation = parseInt(all_hits.indexOf(parseInt(annotationId, 10)), 10) + 1;
                $('.annotation_current_count_' + collectionResource.transcripts.selected_transcript).text(collectionResource.transcripts.annotation_markers.currentIndexAnnotation);
                firstTimeAnnotation = 0;
            }

            $.ajax({
                url: $('#enter_annotation_text').data('url') + '/' + annotationId,
                type: 'GET',
                dataType: 'json',
                success: function (response) {
                    let targetInfo = JSON.parse(response.target_info);
                    $('.annotation-box .readable-text').html(response.body_content);
                    $('.annotation-box .readable-text').removeClass('d-none');
                    var ed = tinyMCE.get('enter_annotation_text');
                    ed.setContent(response.body_content);
                    $('.annotation-box .annotation_text').html(' ' + $('.annotation_' + annotationId).text());
                    $('.annotation_' + annotationId).parents('.content_section').prev().children().clone().prependTo('.annotation-box .annotation_text');
                    $('.annotation-box-holder').removeClass('d-none');
                    $('.annotation-box').removeClass('d-none');
                    $('.annotation-box .editable-text').addClass('d-none');
                    $('.annotation-box .done_annotation').addClass('d-none');
                    $('.annotation-box .cancel_annotation').addClass('d-none');
                    $('.annotation-box .close_annotation').removeClass('d-none');
                    $('.edit_text_annotation').prop('disabled', false);
                    $('.edit_text_annotation').data('annotation', annotationId);
                    $('.delete_text_annotation').prop('disabled', false);
                    $('.delete_text_annotation').data('annotation', annotationId);

                    adjustAnnotationSectionHeight();
                    $('.annotation_markers_' + collectionResource.transcripts.selected_transcript).removeClass('d-none');
                    setTimeout(function () {
                        adjustAnnotationSectionHeight();
                        if (collectionResource.search_text_val != '' && collectionResource.search_text_val != 0) {
                            $.each(collectionResource.search_text_val, function (identifier, keyword) {
                                keyword = clearKeyWords(keyword);
                                $('.annotation-box .readable-text p').mark(keyword, {
                                    "element": "span",
                                    "className": "highlight-marker mark " + identifier,
                                    "caseSensitive": false,
                                    "separateWordSearch": false
                                });
                            });
                            $('.transcript #overlay-counters').addClass('d-none');
                        }
                        setTimeout(function () {
                            let identifier = $('#clicked_identifier').val();
                            if (typeof identifier != 'undefined' && identifier) {
                                if ($('#identifier_movement').val() > 0) {
                                    $('.readable-text.annotation-information .highlight-marker.mark.' + identifier + ':first').addClass('current');
                                } else {
                                    $('.readable-text.annotation-information .highlight-marker.mark.' + identifier + ':last').addClass('current');
                                }
                            }
                        }, 100);
                    }, 500);


                },

            });

        });
    };

    /**
     *  The addAnnotation method is responsible for managing all the functionality and events related to add annotation.
     *
     */
    const addAnnotation = function () {
        document_level_binding_element('.add_text_annotation', 'click', function () {
            if (window.getSelection && document.createRange) {
                var selection = window.getSelection();
                if (selection.rangeCount > 0) {
                    let starttNode = selection.getRangeAt(0).startContainer.parentNode;
                    let endNode = selection.getRangeAt(0).endContainer.parentNode;
                    if (starttNode == endNode) {
                        if ($(starttNode).hasClass('file_transcript_mark_custom')) {
                            let baseNode = selection.baseNode;
                            if (typeof selection.baseNode == 'undefined')
                                baseNode = selection.focusNode;
                            let startOffset = getSelectionOffsetRelativeTo(baseNode.parentNode);
                            let endOffset = selection.getRangeAt(0).toString().length + startOffset;

                            let target_info = {
                                time: $(starttNode).data('time'),
                                pointId: $(starttNode).data('point'),
                                text: selection.toString(),
                                startOffset: startOffset,
                                endOffset: endOffset
                            };
                            annotationParams = {
                                annotation_set_id: parseInt($('#annotation_set_select').val(), 10),
                                target_type: 'text',
                                target_content_id: parseInt($('#file_transcript_select').val(), 10),
                                target_content: 'FileTranscript',
                                target_sub_id: $(starttNode).data('point'),
                                target_info: JSON.stringify(target_info)
                            }
                            $('.annotation-box').removeClass('d-none');
                            $('.annotation-box-holder').removeClass('d-none');
                            $('.annotation-box .editable-text').removeClass('d-none');
                            $('.annotation-box .readable-text').addClass('d-none');
                            $('.annotation-box .title').html(selection.toString());
                            $('.annotation-box .done_annotation').removeClass('d-none');
                            $('.annotation-box .cancel_annotation').removeClass('d-none');
                            $('.annotation-box .close_annotation').addClass('d-none');
                            $('.annotation-box .button_handle').addClass('d-none');
                            $('.edit_text_annotation').prop('disabled', true);
                            $('.delete_text_annotation').prop('disabled', true);
                            var ed = tinyMCE.get('enter_annotation_text');
                            ed.setContent('');
                            $('html,body').animate({
                                    scrollTop: $("#annotation_section").offset().top
                                },
                                'slow');
                        } else {
                            invalidSelection();
                            clearSelection();
                        }
                    } else {
                        invalidSelection('Select the text within a single transcript point without speaker.')
                    }

                } else {
                    invalidSelection();
                    clearSelection();
                }

            } else if (document.selection) {
                document.selection.createRange().parentElement();
                clearSelection();
            } else {
                invalidSelection();
            }
        });
    };

    /**
     *  The editAnnotation method is responsible for managing all the functionality and events related to edit annotation.
     *
     */
    const editAnnotation = function () {
        document_level_binding_element('.edit_text_annotation', 'click', function () {
            $('.annotation-box .readable-text').addClass('d-none');
            $('.annotation-box .editable-text').removeClass('d-none');
            $('.annotation-box .done_annotation').removeClass('d-none');
            $('.annotation-box .cancel_annotation').removeClass('d-none');
            $('.annotation-box .close_annotation').addClass('d-none');
            $('html,body').animate({
                    scrollTop: $("#annotation_section").offset().top
                },
                'slow');
        });
    };

    /**
     *  The saveOrCancelAnnotation method is responsible for sending the request to add or edit annotation.
     *
     */
    const saveOrCancelAnnotation = function () {
        if ($('.enter_annotation_text').length > 0) {
            init_tinymce_for_element('.enter_annotation_text', {
                selector: '.enter_annotation_text',
                height: $('.enter_annotation_text').attr('height'),
                plugins: 'paste link charmap hr anchor wordcount',
                menubar: false,
                toolbar: "undo redo | bold italic underline link",
                branding: false,
                paste_as_text: true,
                content_style: "body {font-size: 14px;}"
            });
            var ed = tinyMCE.get('enter_annotation_text');
            ed.on('keyup', function (e) {
                let length = $.trim(ed.getContent({format: 'text'})).length;
                if (length > 0)
                    $('.done_annotation').prop('disabled', false);
                else
                    $('.done_annotation').prop('disabled', true);
            });

            document_level_binding_element('.cancel_annotation, .close_annotation', 'click', function () {
                var ed = tinyMCE.get('enter_annotation_text');
                ed.setContent('');
                $('.annotation-box').addClass('d-none');
                $('.annotation-box-holder').addClass('d-none');
                $('.annotation_flag, .annotation_marker').removeClass('active');
                $('.delete_text_annotation').prop('disabled', true);
                $('.edit_text_annotation').prop('disabled', true);
                $('.annotation-option').removeClass('d-none');
                $('.annotation_delete_section').addClass('d-none');
                clearSelection();
            });
            document_level_binding_element('.done_annotation', 'click', function () {
                annotationParams.body_type = 'text';
                annotationParams.body_format = 'html';
                annotationParams.body_content = ed.getContent();
                let annotationQuery = '.json';
                let requestMethod = 'POST';
                if (!$('.edit_text_annotation').prop('disabled')) {
                    let annotationId = $('.edit_text_annotation').data('annotation');
                    annotationQuery = '/' + annotationId + '.json';
                    requestMethod = 'PUT';
                }
                let url = $('#enter_annotation_text').data('url') + annotationQuery;
                $('.done_annotation').prop('disabled', true);
                $.ajax({
                    url: url,
                    data: annotationParams,
                    type: requestMethod,
                    dataType: 'json',
                    success: function (response) {
                        clearSelection();
                        $('#annotation_message').html(response.msg);
                        let page_number_transcript = collectionResource.transcripts.transcript_page_number;
                        lastAnnotationId = response.id;
                        collectionResource.transcripts.specific_page_load_transcript('clear', parseInt(page_number_transcript, 10));
                        setTimeout(function () {
                            $('#annotation_message').html('');
                            var ed = tinyMCE.get('enter_annotation_text');
                            ed.setContent('');
                        }, 5000);
                        that.update_hits_annotation(collectionResource.transcripts.selected_transcript);
                    },

                });
            });
        }
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

    this.update_hits_annotation = function (selected_transcript) {
        if ($('.refresh_hits_annotation_' + selected_transcript).length > 0) {
            let data = {
                action: 'refresh_hits_annotation',
                selected_transcript: selected_transcript
            };
            app_helper.classAction($('.refresh_hits_annotation_' + selected_transcript).data('url'), data, 'JSON', 'POST', '', that, false);
        }
    };

    this.refresh_hits_annotation = function (response, _container, requestData) {
        $('.annotation_markers_' + requestData['selected_transcript']).removeClass('d-none');
        collectionResource.annotation_hits_count = response['annotation_count']['hits'];
        collectionResource.annotation_hits_ids = response['annotation_count']['annotation_ids'];

        try {
            $('.annotation_current_total').html(response['annotation_count']['hits']['total'][requestData['selected_transcript']])
        } catch (e) {
            e;
        }
    };

    const adjustAnnotationSectionHeight = function () {
        let height = $('.two_col_custom').height() - $('.resource_top_section').height();
        if ($('.search-result-bottom.transcript.open').length > 0) {
            height = height - $('.search-result-bottom.transcript.open').height();
        }
        let bodyWidth = $('body').width();
        if(bodyWidth >= 1500)
            $('.annotation-box-holder').css('min-height', '60px');
        else if(bodyWidth >= 1200 && bodyWidth < 1500)
            $('.annotation-box-holder').css('min-height', '170px');
        else if(bodyWidth >= 1024 && bodyWidth < 1200)
            $('.annotation-box-holder').css('min-height', '230px');
        //$('.annotation-box .readable-text').css('max-height', (height - 200) + 'px');
        // $('.annotation-box-holder').css('height', (height - 200) + 'px');
        // $('.annotation-box-holder .annotation-box').css('height', (height - 100) + 'px');
        //$('.annotation-box .editable-text .tox-tinymce').css('max-height', (height - 57) + 'px');
    };
    /**
     * The initializeAnnotation activate all the functionality and events needs for the annotation.
     */
    const initializeAnnotation = function () {
        showAnnotation();
        addAnnotation();
        deleteAnnotation();
        editAnnotation();
        saveOrCancelAnnotation();

    };

    /**
     * The invalidSelection method show the error message.
     *
     * @param message
     */
    const invalidSelection = function (message) {
        if (typeof message == 'undefined')
            message = 'Highlight transcript text to add a new annotation.';
        jsMessages('danger', message);
    };

    /**
     * The clearSelection method clear the current selection of the browser.
     *
     */
    const clearSelection = function () {
        if (window.getSelection) {
            if (window.getSelection().empty) {  // Chrome
                window.getSelection().empty();
            } else if (window.getSelection().removeAllRanges) {  // Firefox
                window.getSelection().removeAllRanges();
            }
        } else if (document.selection) {  // IE?
            document.selection.empty();
        }
    }
}
