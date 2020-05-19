$ ->
  sortble_active = ->
    $('#sort_resource_files').sortable(
      handle: '.handle'
      stop: updateIndex).disableSelection()

  addPhoto = (file) ->
    $('#photos').append HandlebarsTemplates['photos/show'](file)

  removePhoto = (element) ->
    $.ajax
      url: element.data('delete-url')
      type: 'post'
      dataType: 'script'
      data: {'_method': 'delete'}
      success: ->
        element.fadeOut()

  renderPhotos = (photos) ->
    addPhoto photo for photo in photos

  $('#fileupload').fileupload
    dataType: 'json'
    url: $('#fileupload').data('photos-path')
    done: (e, data) ->
      addPhoto file for file in data.result

  if $('#photos').length
    $.getJSON $('#photos').data('json-url'), (results) ->
      renderPhotos results.gallery.photos

  $('#photos').on "click", ".photo-delete", (event) ->
    removePhoto $('#photos').closest(".photo")
    event.preventDefault()

  fixHelperModified = (e, tr) ->
    $originals = tr.children()
    $helper = tr.clone()
    $helper.children().each (index) ->
      $(this).width $originals.eq(index).width()
    $helper

  updateIndex = (e, ui) ->
    $('li.index', ui.item.parent()).each (i) ->
      $(this).html i + 1

    field_values = {}

    values = {}
    $('.sort-order-field').each (i) ->
      $(this).val(i + 1)
      field_values[$(this).data("id")] = $(this).val()

    values["resource_file_sort"] = field_values

    $.ajax
      type: 'POST'
      url: $("#sort_resource_files").data('path')
      data: values
      beforeSend: ->
      error: (xhr, ajaxOptions, thrownError) ->
        er = JSON.parse(xhr.responseText)
      success: (data) ->

  sortble_active()
  $(".delete-resource-file").on 'click', (e) ->
    e.preventDefault()
    $('#delete_resource_file_popup').modal('show')
    $('#delete_resource_file_button').attr('href', $(this).attr('href'))

  $('.best_in_place').best_in_place()
  $('.best_in_place').bind 'ajax:success', ->
    $('.display_title').val($('.best_in_place').text())
    return

  $(".edit_title").on 'click', () ->
    $(this).parent().find("span").click();
    $(this).addClass("d-none");

  $(".best_in_place").on 'focusout', () ->
    $(this).parent().find("i.edit_title").removeClass("d-none");