# Utilities
module Utilities
  # Utilities::AviaryDomainHandler
  class PublicShareUtilities < Utilities::BaseUtility
    def initialize
      super
    end

    def self.should_have_public_access(share_code, url)
      crypt = ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base[0..31], Rails.application.secrets.secret_key_base)
      date_range = crypt.decrypt_and_verify(share_code).split(' ')
      current_date = Time.now.beginning_of_day.to_i
      url.split('/').include?(date_range[2]) && current_date.to_i >= Date.strptime(date_range[0], '%m-%d-%Y').to_time.to_i && current_date <= Date.strptime(date_range[1], '%m-%d-%Y').to_time.to_i
    rescue StandardError => ex
      puts ex
      false
    end
  end
end
