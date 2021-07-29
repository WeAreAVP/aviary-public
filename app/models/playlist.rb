# Playlist
# Author::    Furqan Wasi  (mailto:furqan@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
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

  def self.fetch_list(page, per_page, query, organization_id, export = false)
    playlists = Playlist.joins(%i[organization]) if organization_id.present?
    playlists = playlists.where('playlists.organization_id = ? ', organization_id)
    if query.present?
      query = query.downcase.strip
      # featured status search
      status = true if 'yes'.include? query
      status = false if 'no'.include? query
      # public status search
      access_public_status = 1 if 'yes'.include? query
      access_public_status = 0 if 'no'.include? query
      query_string_name = 'playlists.name LIKE (?)'
      query_string_playlist_resources_count = query.is_i? ? 'playlists.playlist_resources_count = ? ' : ' "' + Time.now.to_i .to_s + '" = ? '
      query_string_organizations = 'organizations.id =?'
      playlists = if status.nil? && access_public_status.nil?
                    playlists.where("(#{query_string_name} OR #{query_string_playlist_resources_count}) AND #{query_string_organizations}", "%#{query}%", query, organization_id)
                  else
                    playlists.where("(#{query_string_name} OR #{query_string_playlist_resources_count} OR playlists.is_featured =? OR playlists.access = ?) AND #{query_string_organizations}", "%#{query}%",
                                    query, status, access_public_status, organization_id)
                  end
    end
    count = playlists.size
    playlists = playlists.limit(per_page).offset((page - 1) * per_page) unless export
    [playlists, count]
  end
end
