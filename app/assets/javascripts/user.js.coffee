$ ->

  $("#addingOrgUserRoleCus").on "click", (e) ->
    e.preventDefault()
    $('.add-team-member-form input[name="user[][search]"]').each (index) ->
      if($(this).val() == "")
        jsMessages('danger','Email cannot be blank.')
        return false
    $.ajax
      type: 'POST'
      url: $(".add-team-member-form").attr('action')
      data: $(".add-team-member-form").serialize()
      beforeSend: () ->
        $("#addingOrgUserRoleCus, #add_member_row").css('display', 'none')
        $("#loader").removeClass("d-none")
        $(".add-team-member-form").addClass("d-none")
      error: (xhr, ajaxOptions, thrownError) ->
        er = JSON.parse(xhr.responseText)
      success: (data) ->
        message = "<dl>"
        $.each data.message, (index, value) ->
          if(value.atype == "success")
            msg_class = "text-success"
          else
            msg_class ="text-danger"
          if(value.user.length > 0)
            message += '<dt class="'+ msg_class+' font-weight-bold">' + value.message + "</dt>"
            message += '<dd class='+ msg_class+' style="margin: 11px 40px;">' + value.user + "</dd>"
        message += "</dl>"
        $("#AddTeamMemberModal .modal-body .data-table").html(message)

  $("#add_member_row").on "click", (e) ->
    member_row = $("#AddTeamMemberModal .modal-body .data-table").data("member_row")
    $.ajax
      type: 'GET'
      url: member_row
      beforeSend: ->
      error: (xhr, ajaxOptions, thrownError) ->
        er = JSON.parse(xhr.responseText)
      success: (data) ->
        $(".add-team-member-form").append(data.partial)
        $('select[name="user[][user_role]"]').selectize()
        remove_member_rows()


  remove_member_rows = () ->
    $(".remove_member_row").on "click", (e) ->
      $(this).parent().parent().remove();


  $('#AddTeamMemberModal').on 'hidden.bs.modal', ->
    $('#search_team_members').val('')

  $(".update_cus_prof").on "click", (e) ->
    e.preventDefault()
    if (($("#user_password").val() == '' && $("#user_password_confirmation").val() == ''))
      $(".edit-user-form").submit()
    else
      $("#with_password_modal").modal('show')