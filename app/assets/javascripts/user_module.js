/**
 * User operations
 *
 * @author Furqan Wasi<furqan@weareavp.com, furqan.wasi66@gmail.com>
 *
 * User  Handler
 *
 * @returns {User}
 */

var selfUser;

function User(app_helpers) {

    selfUser = this;
    selfUser.app_helper = app_helper;
    this.initialize = function () {

        $('#AddTeamMemberModal').on('hidden.bs.modal', function (e) {
            window.location.reload();
        });
        bindings();
    };

    /**
     *
     * @param response
     * @param container
     * @param requestData
     */
    this.handlecallback = function (response, container, requestData) {
        eval("selfUser." + requestData.action + "(response,container)");
    };

    /**
     *
     * @param response
     * @param container
     */
    this.changeUserOrgRole = function (response, container) {
        this.general_message(response);
    };

    /**
     *
     * @param response
     * @param container
     */
    this.changeUserOrgStatus = function (response, container) {
        this.general_message(response);
    };

    this.general_message = function (response) {
        if (typeof response != "undefined" && response.length > 0 && typeof response[0].response != "undefined" && typeof response[0].notice != "undefined" && response[0].response == 1) {
            $(".messageModalBodyCus").html('<span class="text-success">Information Successfully updated</span>');
        } else {
            $(".messageModalBodyCus").html('<span class="text-danger">Information is not updated, please try again.</span>');
        }
        $("#messageModal").modal("show");
    };

    /**
     * Bind all elements
     *
     * @returns {undefined}
     */
    const bindings = function () {
        $("#listUserDatatable").dataTable().fnDestroy();
        var listUserDatatable = $("#listUserDatatable").DataTable({
            responsive: true,
            processing: true,
            serverSide: true,
            pageLength: 100,
            destroy: true,
            bInfo: true,
            pagingType: 'simple_numbers',
            'dom': "<'row'<'col-md-6'f><'col-md-6'p>>" +
                "<'row'<'col-md-12'tr>>" +
                "<'row'<'col-md-5'i><'col-md-7'p>>",
            bLengthChange: false,
            columnDefs: [
                {orderable: false, targets: -1}
            ],
            language: {
                info: 'Showing _START_ - _END_ of _TOTAL_',
                infoFiltered: '',
                zeroRecords: 'No User found.',
            },
            ajax: $("#listUserDatatable").data("url"),
            drawCallback: function (settings) {
                $(".toggle-switch__input").bind("click", function () {
                    var details = $(this).data();
                    var check_status = $(this).is(":checked");
                    var data = {
                        user_id: details.userId,
                        org_id: details.organizationId,
                        role_id: details.roleId,
                        status: check_status,
                        action: "changeUserOrgStatus"
                    };
                    selfUser.app_helper.classAction(details.path, data, "JSON", "POST", "", selfUser);
                });

                $(".user_org_role").on("change", function () {
                    var details = $(this).data();
                    var data = {
                        user_id: details.userId,
                        org_id: details.organizationId,
                        role_id: $(this).val(),
                        action: "changeUserOrgRole"
                    };
                    selfUser.app_helper.classAction(details.path, data, "JSON", "POST", "", selfUser);
                });
                $(".remove-user-organization-popup").on("click", function (e) {
                    e.preventDefault();
                    $("#remove_organization_user").modal('show');
                    return $(".remove-organization-user-btn").attr("href", $(this).attr('href'));
                });
                $("select").selectize();
            }
        });
        document.addEventListener("turbolinks:before-cache", function () {
            listUserDatatable.destroy();
        });

        $("#resetPasswordBtn").on("click", function () {
            var html =
                '<div class="col-md-6">\n' +
                '  <div class="form-group">\n' +
                '    <label for="admin_user_password"> <label for="admin_user_password">Password</label></label>\n' +
                '    <input class="form-control" type="password" name="admin_user[password]" id="admin_user_password">\n' +
                '  </div>\n' +
                '</div>\n' +
                '<div class="col-md-6">\n' +
                '  <div class="form-group">\n' +
                '    <label for="admin_user_password_confirmation"> <label for="admin_user_password_confirmation">' +
                'Password confirmation</label></label>\n' +
                '    <input class="form-control" type="password" name="admin_user[password_confirmation]" ' +
                ' id="admin_user_password_confirmation">\n' +
                '  </div>\n' +
                '</div>\n';
            $("#resetPassword").html(html);
        });
    };

    /**
     *
     * @param response
     * @param container
     */
    this.addTeamMember = function (response, container) {

        if (typeof response != "undefined" && response.length > 0
            && typeof response[0].response != "undefined" && typeof response[0].notice != "undefined") {

            if (response[0].response == 1) {
                jsMessages('success', response[0].notice);
            } else {
                jsMessages('danger', response[0].notice);

            }
        } else {
            jsMessages('danger', 'Something went wrong, no action is performed.');

        }
    };
}
