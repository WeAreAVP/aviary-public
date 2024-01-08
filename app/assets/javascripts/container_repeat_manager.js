/**
 * Container Repeat Manager
 *
 * @author Furqan Wasi <furqan@weareavp.com>
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 */
"use strict";

function ContainerRepeatManager() {
    var that = this;
    this.initialize = function () {
    };

    /**
     *
     * @param addButtonElement
     * @param removeButtonElement
     * @param cloneContainer
     * @param appendToContainer
     */
    this.makeContainerRepeatable = function (addButtonElement, removeButtonElement, cloneContainer, appendToContainer, fieldsReset) {
        document_level_binding_element(addButtonElement, 'click', function (e) {
            let cloned = $($(cloneContainer)[0]).clone();
            $(appendToContainer).append(cloned);
            $(cloned).find(fieldsReset).val('');
        });

        document_level_binding_element(removeButtonElement, 'click', function (e) {
            $(this).parents(cloneContainer).remove();
        });

    }
}
