/**
 * Search Page operations
 *
 * @author Raza Saleem<raza@weareavp.com>
 *
 * MyResources Handler
 *
 * @returns {MyResources}
 *
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 */

 var selfMyResources;

 function MyResources() {
     selfMyResources = this;
     selfMyResources.appHelper = new App();
     /**
      *
      * @returns {none}
      */
     this.initialize = function () {
        $('.pagination a').each(function( index ) {
            url = $(this).attr('href')
            if(url.includes("catalog"))
            {
                console.log('selfMyResources.appHelper',)
                var new_url = '/myresources/listing';
                var page = selfMyResources.appHelper.getUrlParameter(url)[0]["page"];
                if (typeof page !== 'undefined') new_url = new_url+'?page='+page;
                $(this).attr('href',new_url);
            }
        });
        bindings();
     };
 
     /**
      * Bind all elements
      *
      * @returns {undefined}
      */
     const bindings = function () {
        document_level_binding_element('#export_to_resource_list ', 'click', function () {
            if ($('#number_of_selected_resources').html().trim() === '' || $('#number_of_selected_resources').html().trim() === '0') {
                jsMessages('danger', 'Please select atleast one resource.');
            } else {
                window.open($('#export_to_resource_list').data().url, '_blank').focus();
            }
        });
        document_level_binding_element('.myresources_edit', 'click', function () {
 
            $('#modalPopupForm').attr('action', $(this).data().url);
            $('#modalPopupForm').attr('method', 'post');
            html = '<table class="table table-hover review_resources-list table-sm " style="width: 100%;">'+
            '<thead>'+
            '<tr>'+
            '  <td class="font-weight-bold"> ID</td>'+
            '  <td class="font-weight-bold"> Resource Name</td>'+
            '  <td class="font-weight-bold"> Note</td>'+
            '</tr>'+
            '</thead>'+
            '<tbody class="bulk-edit-review-resource-list-content">'+
            '<tr>'+
            '  <td>'+$(this).data().id+'</td>'+
            '  <td>'+$(this).data().title+'</td>'+
            '  <td><textarea class="form-control" name="myresources_edit_note" id="myresources_edit_note" rows="3">'+$('#myresource_list_note_'+$(this).data().id).html()+'</textarea>'+
            '       <small class="form-text text-muted mt-2">Previously saved: '+$('#myresource_list_note_'+$(this).data().id).data().update+'</small></td>'+
            '</tr>'+
            '</tbody>'+
            '</table>';
            $('#formModalPopupBody').html(html);
            $('#formModalPopupTitle').html('Edit My Resource');
            $('#formModalPopup').modal('show');
 
         });
 
 
        document_level_binding_element('.myresources_delete', 'click', function () {
            $('#modalPopupTitle').html('Delete My Resource');
            $('#modalPopupBody').html('Are you sure you want to delete this resource? This will remove my resources. This action cannot be undone.');
            $('#modalPopupFooterYes').attr('href', $(this).data().url);
            $('#modalPopup').modal('show');
         });
     };
 }