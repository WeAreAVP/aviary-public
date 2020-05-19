# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$ ->
	$('#search_organization_owner').autocomplete
	  source: (request, response) ->
	    $.ajax
	      url: $('#search_organization_owner').data("path")
	      data: { term: $('#search_organization_owner').val() }
	      success: (data) ->
	        response data
	        return
	    return
	  minLength: 2
	  select: (event, ui) ->
	    $('#selected_organization_owner').val(ui.item.id)
	    $('#search_organization_owner').val(ui.item.value)