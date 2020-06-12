# Playlist Resource
class PlaylistResource < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  belongs_to :collection_resource
  belongs_to :playlist, counter_cache: (ENV['RAILS_ENV'] != 'test')
  has_many :playlist_items, dependent: :destroy
  has_attached_file :thumbnail, styles: { small: '450x230>', processors: %i[thumbnail compression] }, default_url: ''
  validates_attachment_content_type :thumbnail, content_type: %r[\Aimage\/.*\z]
  after_save :update_description

  def update_description
    if description.strip_tags.blank? && collection_resource.custom_field_value('description').present? && !collection_resource.custom_field_value('description').first['value'].strip_tags.blank?
      self.description = Sanitize.fragment(collection_resource.custom_field_value('description').first['value'], elements: %w[p br])
      save
    end
  rescue StandardError => e
    Rails.logger.error e
  end
end
