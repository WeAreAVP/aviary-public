# frozen_string_literal: true

# Users::PasswordsController
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class Users::PasswordsController < Devise::PasswordsController
  respond_to :html, :json

  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?
    if successfully_sent?(resource)
      return render json: { success: true, error: false,
                            validation_success: t('validation_success') }
    else
      validation_error = t('validation_error')
      return render json: { success: false, data: resource,
                            email_error: resource.errors.details[:email].present?,
                            validation_error: validation_error }
    end
  end
end
