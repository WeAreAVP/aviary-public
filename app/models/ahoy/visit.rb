# Ahoy::Visit
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class Ahoy::Visit < ApplicationRecord
  self.table_name = 'ahoy_visits'

  has_many :events, class_name: 'Ahoy::Event'
  belongs_to :user, optional: true
  before_save :update_location

  def update_location
    self.ip = Rails.env.development? ? '101.53.254.80' : ip
    if country.blank?
      begin
        db = MaxMindDB.new(ENV.fetch('GEO_DB_PATH', nil))
        ret = db.lookup(ip)
        region = ret.subdivisions.most_specific.name if region.blank?
        country = ret.country.name if country.blank?
        city = ret.city.name(:fr) if city.blank?
        self.country = country
        self.city = city
        self.region = region
      rescue StandardError => e2
        puts e2
      end
    end
    if ISO3166::Country.find_country_by_name(country)
      self.country = ISO3166::Country.find_country_by_name(country).alpha2
    end
  rescue StandardError => e
    Rails.logger.error e.message
  end
end
