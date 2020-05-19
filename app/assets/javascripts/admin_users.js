/**
 * AdminUsers Management
 *
 * @author Nouman Tayyab <nouman@weareavp.com>
 *
 */

function AdminUsers() {

    this.initialize = function () {
        initDataTable();
    };
    this.pendingUserInitialize = function () {
        $('#admin_pending_user_table').DataTable({
            responsive: true,
            pageLength: 100,
            bInfo: true,
            language: {
                info: 'Showing _START_ - _END_ of _TOTAL_',
                infoFiltered: '',
                zeroRecords: 'No pending user found.',
            },
            pagingType: 'simple_numbers',
            'dom': "<'row'<'col-md-6'f><'col-md-6'p>>" +
                "<'row'<'col-md-12'tr>>" +
                "<'row'<'col-md-5'i><'col-md-7'p>>",
            bLengthChange: false,
            drawCallback: function (settings) {
                initDeletePopup();
            }
        });

    };
    this.initializeForm = function () {
        initDeletePopup();
        bindEvents();
    };
    const bindEvents = function () {
        $('#assign_organization').click(function () {
            let url = $(this).data('path');
            let organization = $('#organizations').val();
            let roles = $('#roles').val();
            let formData = {
                'organization_id': organization,
                'role_id': roles
            }
            if (roles != '' && organization != '') {
                $.ajax({
                    url: url,
                    data: formData,
                    type: 'POST',
                    dataType: 'json',
                    success: function (response) {
                        window.location.reload();
                    },
                });
            }
            else {
                alert('Please select Organization and Role.')
            }
        });
        $('.user_org_role, .toggle-switch__input').change(function () {
            let element = $(this).parents('tr');
            let data = element.data();
            let formData = {
                'organization_id': data.organization,
                'status': element.find('.toggle-switch__input').is(":checked"),
                'role_id': element.find('.user_org_role').val()
            };
            $.ajax({
                url: data.path,
                data: formData,
                type: 'PUT',
                dataType: 'json',
                success: function (response) {
                    jsMessages('success', 'Changes saved successfully.');
                },
            });

        });
    };
    const initDeletePopup = function () {
        $('.admin_user_delete').click(function () {
            $('#modalPopupFooterYes').attr('href', $(this).data().url);
            let message = 'Are you sure you want to remove this user? All user information will be deleted, including association to other organizations.';
            if ($(this).data().type == 'association')
                message = 'Are you sure you want to remove this user? All user information will be deleted, including association to other organizations.';
            else if ($(this).data().type == 'pending')
                message = 'Are you sure you want to remove this user?';
            $('#modalPopupBody').html(message);
            $('#modalPopupTitle').html('Delete "' + $(this).data().name + '"');
            $('#modalPopup').modal('show');
        });
    };
    const initDataTable = function () {
        let dataTableElement = $('#admin_user_data_table');
        if (dataTableElement.length > 0) {
            dataTableElement.DataTable({
                processing: true,
                responsive: true,
                pageLength: 100,
                serverSide: true,
                bInfo: true,
                destroy: true,
                language: {
                    info: 'Showing _START_ - _END_ of _TOTAL_',
                    infoFiltered: '',
                    zeroRecords: 'No User found.',
                },
                pagingType: 'simple_numbers',
                'dom': "<'row'<'col-md-6'f><'col-md-6'p>>" +
                    "<'row'<'col-md-12'tr>>" +
                    "<'row'<'col-md-5'i><'col-md-7'p>>",
                bLengthChange: false,
                ajax: dataTableElement.data("url"),
                drawCallback: function (settings) {
                    initDeletePopup();
                }
            });
        }
    };
}
