# Ahoy::Event
class Ahoy::Event < ApplicationRecord
  include Ahoy::QueryMethods

  self.table_name = 'ahoy_events'

  belongs_to :visit
  belongs_to :user, optional: true
  has_many :search_trackings
  serialize :properties, JSON
end
