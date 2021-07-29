/**
 * User Register
 *
 * @author Furqan Wasi<furqan@weareavp.com, furqan.wasi66@gmail.com>
 *
 * User  Handler
 *
 * @returns {User}
 *
 * Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
 * Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
 */

function UserRegister() {
    var parent_container = null;
    this.initialize = function (parent_container_validation) {
        parent_container = parent_container_validation;
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
        if (pswd == $(parent_container + ' #user_password').val() && pswd != '') {
            $(parent_container + ' .validation_password_match').removeClass('invalid-signup').addClass('valid-signup');
        } else {
            flag = false;
            $(parent_container + ' .validation_password_match').removeClass('valid-signup').addClass('invalid-signup');
        }
        return flag;
    };

    const check_password_strength = function (pswd) {

        let flag = true;
        //validate the length
        if (pswd.length < 8) {
            $(parent_container + ' .validation_length').removeClass('valid-signup').addClass('invalid-signup');
            flag = false;
        } else {
            $(parent_container + ' .validation_length').removeClass('invalid-signup').addClass('valid-signup');
        }

        //validate letter
        if (pswd.match(/[A-z]/)) {
            $(parent_container + ' .validation_letter').removeClass('invalid-signup').addClass('valid-signup');
        } else {
            flag = false;
            $(parent_container + ' .validation_letter').removeClass('valid-signup').addClass('invalid-signup');
        }

        //validate uppercase letter
        if (pswd.match(/[A-Z]/)) {
            $(parent_container + ' .validation_capital').removeClass('invalid-signup').addClass('valid-signup');
        } else {
            flag = false;
            $(parent_container + ' .validation_capital').removeClass('valid-signup').addClass('invalid-signup');
        }
        //validate uppercase letter
        if (pswd.match(/[a-z]/)) {
            $(parent_container + ' .validation_lower').removeClass('invalid-signup').addClass('valid-signup');
        } else {
            flag = false;
            $(parent_container + ' .validation_lower').removeClass('valid-signup').addClass('invalid-signup');
        }
        //special characters
        if (pswd.match(/[.@$!%*?&]/)) {
            $(parent_container + ' .validation_special_character').removeClass('invalid-signup').addClass('valid-signup');
        } else {
            flag = false;
            $(parent_container + ' .validation_special_character').removeClass('valid-signup').addClass('invalid-signup');
        }
        if (pswd.match(/[#()_+=<>/"'{}\[\]\\|`~;:\^\-]/)) {
            flag = false;
            $(parent_container + ' .validation_can_only_have_special_character').removeClass('valid-signup').addClass('invalid-signup');
        } else {
            $(parent_container + ' .validation_can_only_have_special_character').removeClass('invalid-signup').addClass('valid-signup');
        }

        //validate number
        if (pswd.match(/\d/)) {
            $(parent_container + ' .validation_number').removeClass('invalid-signup').addClass('valid-signup');
        } else {
            flag = false;
            $(parent_container + ' .validation_number').removeClass('valid-signup').addClass('invalid-signup');
        }
        return flag;
    };

    /**
     * Bind all elements
     *
     * @returns {undefined}
     */
    const bindings = function () {
        document_level_binding_element(parent_container + ' #user_password_confirmation', 'keyup', function () {
            var pswd = $(this).val();
            check_password_match(pswd);
            check_password_strength($(parent_container + ' #user_password').val());
            $(parent_container + ' .submit-registration-form').removeAttr('disabled');
        });

        document_level_binding_element(parent_container + ' #user_password', 'keyup', function () {
            var pswd = $(this).val();
            check_password_strength(pswd);
            check_password_match($(parent_container + ' #user_password_confirmation').val());
            $(parent_container + ' .submit-registration-form').removeAttr('disabled');
        });

        document_level_binding_element(parent_container + ' #edit_user', 'submit', function (e) {
            if (!check_password_match($(parent_container + ' #user_password_confirmation').val()) || !check_password_strength($(parent_container + ' #user_password').val())) {
                e.preventDefault();
                setTimeout(function () {
                    $(' .edit_reg_confirm').removeAttr('disabled');
                }, 1000);
            }
        });

        document_level_binding_element(' #sign_up_user_form', 'submit', function (e) {
            e.preventDefault();
            if (check_password_match($(parent_container + ' #user_password_confirmation').val()) && check_password_strength($(parent_container + ' #user_password').val())) {
                $.ajax({
                    type: 'POST',
                    url: $("#sign_up_user_form").attr('action'),
                    data: $("#sign_up_user_form").serialize(),
                    dataType: 'json',
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
                            return $(parent_container + ' .submit-registration-form').prop("disabled", false);
                        }
                    }
                });
            }
        });
    };
}
