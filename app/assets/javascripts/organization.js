/**
 * Organization Management
 *
 * @author Nouman Tayyab <nouman@weareavp.com>
 *
 */
"use strict";

function Organization() {

    this.orgFormPageBinding = function () {
        init_tinymce_for_element('#organization_description');
    };

    this.init_org_display_settings = function () {
        let display_settings = new DisplaySettings();
        display_settings.init_display_settings('organization');
    };

}
