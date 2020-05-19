# frozen_string_literal: true

# Users::RegistrationsController
class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :html, :json
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  def create
    build_resource(sign_up_params)
    resource.updated_by_id = rand(6)
    resource.created_by_id = rand(6)
    resource.save
    if resource.valid?
      resource.update(updated_by_id: resource.id, created_by_id: resource.id)
      return render json: { success: true, message: t('devise.registrations.signed_up_but_unconfirmed') }
    else
      clean_up_passwords resource
      set_minimum_password_length
      validation_error = t('validation_error')
      return render json: { success: false, errors: resource.errors.messages, validation_error: validation_error }
    end
  end

  protected

  def update_resource(resource, params)
    return super if params['password'].present?
    resource.update_without_password(params.except('current_password'))
  end

  def after_update_path_for(resource)
    resource
    profile_path
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up,
                                      keys: %I[first_name last_name agreement photo username preferred_language
                                               receive_emails first_url])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update,
                                      keys: %I[first_name last_name agreement photo username preferred_language
                                               receive_emails])
  end
end
