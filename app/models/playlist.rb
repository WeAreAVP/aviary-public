# Playlist
# Author::    Furqan Wasi  (mailto:furqan@weareavp.com)
class Playlist < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  validates_presence_of :name
  has_many :playlist_resources, dependent: :destroy
  has_many :playlist_items, dependent: :destroy
  has_attached_file :thumbnail, styles: { small: '450x230>', processors: %i[thumbnail compression] }, default_url: ''
  validates_attachment_content_type :thumbnail, content_type: %r[\Aimage\/.*\z]
  enum access: %i[access_private access_public]
  scope :is_featured, -> { where(is_public: true, is_featured: true) }
  scope :is_featured_only, -> { where(is_featured: true) }
  scope :public_playlists, -> { where(access: 'access_public') }
  scope :order_feature_name, -> { order('is_featured DESC, lower(name) ASC') }
  before_save :process_fields
  def public?
    self.class.accesses[access.to_sym] == self.class.accesses[:access_public]
  end

  def process_fields
    self.description = description.strip_tags if description.present?
  end

  def private?
    self.class.accesses[access.to_sym] == self.class.accesses[:access_private]
  end

  def self.to_csv(current_organization)
    playlists = current_organization.playlists
    attributes = %w{Name Entries Featured Public}

    CSV.generate(headers: true) do |csv|
      csv << attributes

      playlists.each do |c|
        is_feature = c.is_featured ? 'Yes' : 'No'
        is_public = c.public? ? 'Yes' : 'No'
        csv << [c.name, c.playlist_items_count, is_feature, is_public]
      end
    end
  end
end
