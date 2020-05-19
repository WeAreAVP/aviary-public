/**
 * User Register
 *
 * @author Furqan Wasi<furqan@weareavp.com, furqan.wasi66@gmail.com>
 *
 * User  Handler
 *
 * @returns {User}
 */

var selfUser;

function UserRegister(app_helpers) {

    selfUser = this;
    selfUser.app_helper = app_helper;
    this.initialize = function () {
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

    const check_password_match = function (pswd) {
        let flag = true;
        if (pswd == $('#sign_up_user_form #user_password').val() && pswd != '') {
            $('#password_match').removeClass('invalid-signup').addClass('valid-signup');
        } else {
            flag = false;
            $('#password_match').removeClass('valid-signup').addClass('invalid-signup');
        }
        return flag;
    };

    const check_password_strength = function (pswd) {

        let flag = true;
        //validate the length
        if (pswd.length < 8) {
            $('#length').removeClass('valid-signup').addClass('invalid-signup');
            flag = false;
        } else {
            $('#length').removeClass('invalid-signup').addClass('valid-signup');
        }

        //validate letter
        if (pswd.match(/[A-z]/)) {
            $('#letter').removeClass('invalid-signup').addClass('valid-signup');
        } else {
            flag = false;
            $('#letter').removeClass('valid-signup').addClass('invalid-signup');
        }

        //validate uppercase letter
        if (pswd.match(/[A-Z]/)) {
            $('#capital').removeClass('invalid-signup').addClass('valid-signup');
        } else {
            flag = false;
            $('#capital').removeClass('valid-signup').addClass('invalid-signup');
        }
        //validate uppercase letter
        if (pswd.match(/[a-z]/)) {
            $('#lower').removeClass('invalid-signup').addClass('valid-signup');
        } else {
            flag = false;
            $('#lower').removeClass('valid-signup').addClass('invalid-signup');
        }
        //special characters
        if (pswd.match(/[.@$!%*?&]/)) {
            $('#special_character').removeClass('invalid-signup').addClass('valid-signup');
        } else {
            flag = false;
            $('#special_character').removeClass('valid-signup').addClass('invalid-signup');
        }
        if (pswd.match(/[#()_+=<>/"'{}\[\]\\|`~;:\^\-]/)) {
            flag = false;
            $('#can_only_have_special_character').removeClass('valid-signup').addClass('invalid-signup');
        } else {
            $('#can_only_have_special_character').removeClass('invalid-signup').addClass('valid-signup');
        }

        //validate number
        if (pswd.match(/\d/)) {
            $('#number').removeClass('invalid-signup').addClass('valid-signup');
        } else {
            flag = false;
            $('#number').removeClass('valid-signup').addClass('invalid-signup');
        }
        return flag;
    };

    /**
     * Bind all elements
     *
     * @returns {undefined}
     */
    const bindings = function () {
        $('#sign_up_user_form #user_password_confirmation').keyup(function () {
            var pswd = $(this).val();
            check_password_match(pswd);
            check_password_strength($('#sign_up_user_form #user_password').val());
            $('.submit-registration-form').removeAttr('disabled');
        });

        $('#sign_up_user_form #user_password').keyup(function () {
            var pswd = $(this).val();
            check_password_strength(pswd);
            check_password_match($('#sign_up_user_form #user_password_confirmation').val());
            $('.submit-registration-form').removeAttr('disabled');
        });

        $("#sign_up_user_form").on("submit", function (e) {
            e.preventDefault();
            if (check_password_match($('#sign_up_user_form #user_password_confirmation').val()) && check_password_strength($('#sign_up_user_form #user_password').val())) {
                $.ajax({
                    type: 'POST',
                    url: $("#sign_up_user_form").attr('action'),
                    data: $("#sign_up_user_form").serialize(),
                    beforeSend: function () {
                    },
                    error: function (xhr, ajaxOptions, thrownError) {
                        var er;
                        er = JSON.parse(xhr.responseText);
                        return console.log(er);
                    },
                    success: function (data) {
                        var msg;
                        msg = '';
                        if (data.success) {
                            $('#signupmodal').modal('hide');
                            $('#general_modal_title_cust').html('Confirmation Required');
                            $('.general_modal_body_cust').html(data.message);
                            return $('#general_modal_message_cust').modal();
                        } else {
                            if (typeof data.show_only_valiation !== 'undefined' && data.show_only_valiation === true) {
                                msg = data.validation_error;
                            } else {
                                $.each(data.errors, function (index, value) {
                                    if (msg === '') {
                                        return msg += index.charAt(0).toUpperCase() + index.slice(1).replace(/_/g, " ") + ': ' + value.join(", ");
                                    }
                                });
                            }
                            jsMessages('danger', msg);
                            return $('.submit-registration-form').prop("disabled", false);
                        }
                    }
                });
            }
        });
    };
}
