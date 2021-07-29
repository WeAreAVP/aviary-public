/**
 * Organization Management
 *
 * @author Nouman Tayyab <nouman@weareavp.com>
 *
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 *
 */
"use strict";

function Organization() {

    this.orgFormPageBinding = function () {
        removeImageCustom();
        init_tinymce_for_element('#organization_description');
    };

    this.init_org_display_settings = function () {
        let display_settings = new DisplaySettings();
        display_settings.init_display_settings('organization');
    };

    const updateSortInfo = function () {
        let info = {};
        $('tr.facet_field').each(function (index, _value) {
            let status = $(this).find('.template-data-field-is-facetable').prop('checked')
            info[index] = {
                key: $(this).data('facet-field'),
                label: $(this).data('label'),
                status: status,
                type: $(this).data('facet-field-type'),
                is_default_field: $(this).data('is-default-field'),
                collection: $(this).data('collection')
            };
        });
        $('.sort_info_search').text(JSON.stringify(info));
    }

    this.initFacetFields = function () {
        $('#sort_facet_fields_table tbody').sortable({
            axis: "y",
            containment: "parent",
            cursor: "move",
            items: "tr",
            tolerance: "pointer",
            stop: updateSortInfo,
        });
        document_level_binding_element('.template-data-is-facetable', 'change', function (e) {
            updateSortInfo();
        });
        document_level_binding_element('.update-forms-btn', 'click', function (e) {
            $('.sort-search-field-form').submit();
        });
        setTimeout(function () {
            updateSortInfo();
        }, 2000);
        initToolTip(false);
    };
}
