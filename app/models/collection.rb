# Collection
class Collection < ApplicationRecord
  belongs_to :organization
  has_many :collection_resources, dependent: :destroy
  enum status: %i[deleted active]
  default_scope { where.not('collections.status=?', Collection.statuses[:deleted]) }
  validates_presence_of :title
  validates_inclusion_of :is_public, :is_featured, in: [true, false], message: 'requires an answer'
  has_attached_file :image, styles: { small: '450x230>', processors: %i[thumbnail compression] }, default_url: ''
  has_attached_file :banner_title_image, styles: { small: '200x90>', processors: %i[thumbnail compression] }, validate_media_type: false, default_url: ''
  has_attached_file :card_image, styles: { small: '200x90>', processors: %i[thumbnail compression] }, validate_media_type: false, default_url: ''
  validates_attachment_content_type :image, content_type: %r[\Aimage\/.*\z]
  has_attached_file :favicon, styles: { small: '40x40>', medium: '64x64>', processors: %i[thumbnail compression] }, validate_media_type: false, default_url: ''
  validates_attachment_content_type :favicon, content_type: %r[\Aimage\/(png|jpeg|jpg|x-icon|vnd.microsoft.icon)\z]
  validates_attachment_content_type :card_image, content_type: %r[\Aimage\/(png|jpeg|jpg|x-icon|vnd.microsoft.icon)\z]
  enum banner_type: %i[banner_image featured_resources_slider]
  enum default_tab_selection: %i[resources about]
  attr_accessor :collection_values_solr
  before_save :collection_values_fetch, :update_default_values
  after_destroy :remove_from_solr
  after_save :solr_index
  custom_fields?
  attr_accessor :dynamic_initializer

  def init_dynamic_initializer
    @dynamic_initializer = {
      field_types: %w[Collection CollectionResource],
      parent_entity: nil
    }
  end

  def collection_card_image
    card_image.present? ? card_image.url(:small) : image.url(:small)
  end

  def update_default_values
    self.default_tab_selection = 0 if default_tab_selection.blank?
    self.status ||= Collection.statuses[:active]
    self.image = open("#{Rails.root}/public/aviary_default_collection.png") unless image.present?
  end

  def remove_from_solr
    Sunspot.remove_by_id(Collection, id)
    Sunspot.commit
  end

  def solr_index
    Sunspot.index self
    Sunspot.commit
  end

  searchable do
    integer :id, stored: true
    integer :collection_collection_id, stored: false do
      id
    end

    integer :organization_id, stored: true
    string :title, stored: true
    text :collection_title, stored: false do
      title
    end
    boolean :is_featured, stored: true
    boolean :is_public, stored: true
    text :about, stored: true
    text :about, stored: false
    string :status, stored: true
    string :document_type, stored: true do
      'collection'
    end

    string :tombstone_fields, multiple: true, stored: true do
      collection_resources.first.tombstone_fields unless collection_resources.empty?
    end
    string :organization_name, multiple: false, stored: true do
      if organization.present?
        organization.name
      else
        ''
      end
    end

    string :collection_identifiers, multiple: true, stored: true do
      collection_values_solr['Identifier'] if collection_values_solr.present? && !collection_values_solr['Identifier'].blank?
    end
    string :collection_creators, multiple: true, stored: true do
      collection_values_solr['Creator'] if collection_values_solr.present? && !collection_values_solr['Creator'].blank?
    end

    string :collection_links, multiple: true, stored: true do
      collection_values_solr['Link'] if collection_values_solr.present? && !collection_values_solr['Link'].blank?
    end

    string :collection_date_spans, multiple: true, stored: true do
      collection_values_solr['Date Span'] if collection_values_solr.present? && !collection_values_solr['Date Span'].blank?
    end

    string :collection_extents, multiple: true, stored: true do
      collection_values_solr['Extent'] if collection_values_solr.present? && !collection_values_solr['Extent'].blank?
    end

    string :collection_languages, multiple: true, stored: true do
      collection_values_solr['Language'] if collection_values_solr.present? && !collection_values_solr['Language'].blank?
    end
  end

  def collection_values_fetch
    self.collection_values_solr = {}
    dynamic_fields = all_fields
    dynamic_fields['Collection'].each do |single_field|
      values = []
      single_field['values'].each do |val|
        if val['vocab_value'].present? || val['value'].present?
          values << val['value']
        end
      end
      if values.present?
        collection_values_solr[single_field['field'].label] = values
      end
    end
  end

  def self.resources_count
    joins(:collection_resources).count
  end

  scope :is_featured, -> { where(is_public: true, is_featured: true) }
  scope :is_featured_only, -> { where(is_featured: true) }
  scope :public_collections, -> { where(is_public: true) }
  scope :order_feature_name, -> { order('is_featured DESC, lower(title) ASC') }

  def connect_collection_default_fields
    FieldType.collection_fields_default.each_with_index do |single, key|
      collection_field = collection_fields.create(field_type_id: single.id, collection_id: id, sort_order: key)
      collection_field.save
    end
  end

  def self.fetch_list(page, per_page, query, organization_id, export = false)
    collections = Collection.joins(%i[organization]) if organization_id.present?
    collections = collections.where('collections.organization_id = ? ', organization_id)
    if query.present?
      query = query.downcase.strip
      status = true if 'yes'.include? query
      status = false if 'no'.include? query
      query_string_collections = 'collections.title LIKE (?)'

      query_string_collection_resources_count = query.is_i? ? 'collections.collection_resources_count = ? ' : ' "' + Time.now.to_i .to_s + '" = ? '
      query_string_organizations = 'organizations.id =?'
      collections = if status.nil?
                      collections.where("(#{query_string_collections} OR #{query_string_collection_resources_count}) AND #{query_string_organizations}", "%#{query}%", query, organization_id)
                    else
                      collections.where("(#{query_string_collections} OR #{query_string_collection_resources_count} OR collections.is_featured =? OR collections.is_public =?) AND #{query_string_organizations}",
                                        "%#{query}%", query, status, status, organization_id)
                    end
    end
    count = collections.size
    collections = collections.limit(per_page).offset((page - 1) * per_page) unless export
    [collections, count]
  end

  def to_csv
    collections = organization.collections
    attributes = %w{Title Resources Featured Public}

    CSV.generate(headers: true) do |csv|
      csv << attributes

      collections.each do |c|
        is_feature = c.is_featured ? 'Yes' : 'No'
        is_public = c.is_public ? 'Yes' : 'No'

        csv << [c.title, c.collection_resources.count, is_feature, is_public]
      end
    end
  end
end
