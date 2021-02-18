$ ->
	$('#ListResourceFileDatatable').dataTable().fnDestroy()
	listUserDatatable = $('#ListResourceFileDatatable').DataTable(
	  responsive: true
	  processing: true
	  serverSide: true
	  pageLength: 100
	  destroy: true
	  bInfo: true
	  pagingType: 'simple_numbers'
	  'dom': '<\'row\'<\'col-md-6\'f><\'col-md-6\'p>>' + '<\'row\'<\'col-md-12\'tr>>' + '<\'row\'<\'col-md-5\'i><\'col-md-7\'p>>'
	  bLengthChange: false
	  columnDefs: [ {
	    orderable: false
	    targets: [ 0, -1, -2, -3 ]
    } ]
	  language:
	    info: 'Showing _START_ - _END_ of _TOTAL_'
	    infoFiltered: ''
	    zeroRecords: 'No Media found.'
	  ajax: $('#ListResourceFileDatatable').data('url')
	)
	document.addEventListener 'turbolinks:before-cache', ->
	  listUserDatatable.destroy()

	$('.manage-resource-file-columns-btn').on 'click', ->
  	$('#manage_resource_file_columns_modal').modal()

  $('.check_all_fields, .uncheck_all_fields').on 'click', ->
  	$('.' + $(this).data('search-field')).prop 'checked', $(this).data('search-status')

  $('#update_resource_file_column_status').on 'click', ->
	  anyBoxesChecked = false
	 	data = { columns_display_status: {}, columns_search_status: {} }

	 	$.each $('.resource_file_identifier'), (index) ->
	    data['columns_display_status'][index] = {value: $(this).attr('id'), status: $(this).prop('checked'), column_name: $(this).data('column'), sort_name: $(this).data('sort')};
	    if $(this).is(':checked')
	      anyBoxesChecked = true

	  if anyBoxesChecked
	    $.each $('.resource_file_search_identifier'), (index) ->
	    	data['columns_search_status'][index] = {value: $(this).attr('id'), status: $(this).prop('checked'), search: $(this).data('search')};

			$.ajax
	      type: 'POST'
	      url: $('#manage_resource_file_columns_modal').data('url')
	      data: data
	      beforeSend: ->
	      	$('.loadingCus').show()
      		$('.loadingtextCus').html('<strong class="font-size-21px">Please Do not close this window. Closing this window will disturb this process. This process might take little longer.').show()
	      error: (xhr, ajaxOptions, thrownError) ->
	        er = JSON.parse(xhr.responseText)
	        console.log er
	      success: (data) ->
	     		jsMessages data.status, data.message
	  			window.setTimeout (->
					  location.reload()
					), 4000

	$(document).on 'click', '.bluk-edit-resource-file-btn', (e) ->
  	if $('input.resources_file_selections:checked').length <= 0
	    jsMessages 'danger', 'Please select Media file(s) before doing bulk operations.'
	  else
	    $('.bulk-edit-resource-file-modal').modal()

	$('.bulk_operation_collection_file').on 'change', ->
  	if $(this).val() == 'change_status'
      showOrHideBulkOptions(['.change_status_content'], ['.bulk_delete_content', '.change_downloadable_status'])
    else if $(this).val() == 'downloadable'
      showOrHideBulkOptions(['.change_downloadable_status'], ['.bulk_delete_content', '.change_status_content'])
    else
      showOrHideBulkOptions(['.bulk_delete_content'], ['.change_status_content', '.change_downloadable_status'])

  showOrHideBulkOptions = (showDivs, hideDivs) ->
    for s in [0...showDivs.length]
      $(showDivs[s]).removeClass('d-none')
    for h in [0...hideDivs.length]
      $(hideDivs[h]).addClass('d-none')


  $('.change_download_enabled_for').on 'change', ->
    if $(this).val() == 'date'
      $('.set_downloadable_duration').datepicker()
    else
      $('.set_downloadable_duration').datepicker('destroy')

  $('.change_downloadable_status_option').on 'change', ->
    if $(this).val() == 'true'
      $("#downloadable_duration").removeClass("d-none");
    else
      $("#downloadable_duration").addClass("d-none");
      $('.change_download_enabled_for').val('');
      $('.set_downloadable_duration').val('');

	$('.bulk-edit-submit-resource-file-btn').on 'click', ->
		ids_array = []
		html_array = []
		$.each $('input.resources_file_selections:checked'), (i) ->
			ids_array.push($(this).data('id'))
			html_array.push('<tr role="row" class="odd">')
			html_array.push('<td>'+$(this).data('id')+'</td>')
			html_array.push('<td >'+$(this).data('name')+'</td>')
			html_array.push('<td >'+$(this).data('colname')+'</td>')
			html_array.push('</tr>')

		html_array = html_array.toString().replace(/,/g, "")
		$('.resource-file-access-type').val($('.change_status_select_option option:selected').val())
		$('.resource-file-check-type').val($('.bulk_operation_collection_file option:selected').val())
		$('.resource-file-ids').val(ids_array)
		$('.bulk-edit-resource-file-modal').modal('hide')
		$('.bulk-edit-review-content-resource-file').html(html_array)
		$('.review_resources_file_bulk').DataTable
		  pageLength: 10
		  bLengthChange: false
		  destroy: true
		  bInfo: true
		$($('.dataTables_wrapper .row .col-md-6')[0]).remove()
		$('.bulk-edit-review-resource-file-modal').modal('show')

	$('.bulk-edit-do-it-resource-file').on 'click', ->
		$.ajax
      type: 'POST'
      url: $(this).data('url')
      data: { check_type: $('.resource-file-check-type').val(), access_type: $('.resource-file-access-type').val(), ids: $('.resource-file-ids').val() }
      beforeSend: ->
      	$('.loadingCus').show()
      	$('.loadingtextCus').html('<strong class="font-size-21px">Please Do not close this window. Closing this window will disturb this process. This process might take little longer.').show()
      error: (xhr, ajaxOptions, thrownError) ->
        er = JSON.parse(xhr.responseText)
        console.log er
      success: (data) ->
     		jsMessages data.status, data.message
				window.setTimeout (->
				  location.reload()
				), 4000

	$(document).on 'click', '#clear_all_selection_resources_file', (e) ->
		e.preventDefault()
		location.reload()

	$('.select_all_checkbox_resources_file').on 'click', (e) ->
		_this = this
		$.each $('.resources_file_selections'), (i) ->
			$(this).prop('checked', $(_this).is(":checked"))

		number_selected = $('input.resources_file_selections:checked').length
		if (typeof $("#ListResourceFileDatatable_filter label .resources_file_selection_count")[0] == 'undefined')
			$('#ListResourceFileDatatable_filter label').append('<div class="resources_file_selection_count"></div>');

		if (number_selected > 0)
      $('#ListResourceFileDatatable_filter label .resources_file_selection_count').html('<span style="color:#f05c1f" class="ml-10px font-weight-bold" id="resource_file_selected">  ( <strong  class="font-size-16px ">' + number_selected + '</strong> resource selected ) </span>  <a href="javascript://" id="clear_all_selection_resources_file">Clear selected</a>');
    else
    	$('#ListResourceFileDatatable_filter label .resources_file_selection_count').remove()
    $('#number_of_bulk_selected_popup').html('<span style="color:#f05c1f" class="ml-10px font-weight-bold" id="resource_selected">  ( <strong  class="font-size-16px ">' + number_selected + '</strong> resource(s) will be affected ) </span>');

	$(document).on 'click', '.resources_file_selections', (e) ->
		number_selected = $('input.resources_file_selections:checked').length
		if (typeof $("#ListResourceFileDatatable_filter label .resources_file_selection_count")[0] == 'undefined')
			$('#ListResourceFileDatatable_filter label').append('<div class="resources_file_selection_count"></div>');
		if (number_selected > 0)
      $('#ListResourceFileDatatable_filter label .resources_file_selection_count').html('<span style="color:#f05c1f" class="ml-10px font-weight-bold" id="resource_file_selected">  ( <strong  class="font-size-16px ">' + number_selected + '</strong> resource selected ) </span>  <a href="javascript://" id="clear_all_selection_resources_file">Clear selected</a>');
    else
    	$('#ListResourceFileDatatable_filter label .resources_file_selection_count').remove()
    $('#number_of_bulk_selected_popup').html('<span style="color:#f05c1f" class="ml-10px font-weight-bold" id="resource_selected">  ( <strong  class="font-size-16px ">' + number_selected + '</strong> resource(s) will be affected ) </span>');
