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

    def self.public_access_handler(share_code, url)
      crypt = EnDecryptor.decrypt(share_code)
      resource_information = crypt.include?('--') ? crypt.split('--') : ''
      unless resource_information.empty?
        public_access_url = PublicAccessUrl.find_by_id(resource_information[0])
        has_access = false
        if public_access_url.present? && public_access_url.status && url.split('/').include?(public_access_url.collection_resource_id.to_s) && URI.decode_www_form_component(public_access_url.url).include?(URI.decode_www_form_component(share_code))
          has_access = if public_access_url.access_type == 'limited_access_url'
                         duration = public_access_url.duration.split(' - ')
                         start_date = duration[0]
                         end_date = duration[1]
                         begin
                           Time.strptime(end_date, '%m-%d-%Y %k:%M') >= Time.now && Time.strptime(start_date, '%m-%d-%Y %k:%M') <= Time.now
                         rescue ArgumentError
                           Date.strptime(end_date, '%m-%d-%Y') >= Time.now.to_date && Date.strptime(start_date, '%m-%d-%Y') <= Time.now.to_date
                         rescue StandardError
                           false
                         end
                       elsif public_access_url.access_type == 'ever_green_url'
                         true
                       end
        end
      end
      has_access
    rescue StandardError
      false
    end
  end
end
