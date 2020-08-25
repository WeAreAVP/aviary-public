# Organization
class Organization < ApplicationRecord
  includes ApplicationHelper

  enum storage_type: { free_storage: 0, no_storage: 1, wasabi_storage: 2 }
  belongs_to :user, optional: true
  has_one :subscription, dependent: :destroy
  has_many :billing_histories, dependent: :destroy
  has_many :collections, dependent: :destroy
  has_many :organization_users, dependent: :destroy
  has_many :playlists, dependent: :destroy
  has_many :playlist_resources, dependent: :destroy
  validates :name, :address_line_1, :url,
            :city, :state, :country, :zip, presence: true
  validates :url, uniqueness: { message: 'Already taken. Please choose another.' }
  validates :logo_image, attachment_presence: true
  validates :banner_image, attachment_presence: true
  validate :validate_url
  enum banner_type: %i[banner_image featured_resources_slider]
  enum banner_title_type: %i[banner_title_image banner_title_text]
  # playlists
  enum default_tab_selection: %i[resources collections about]
  has_attached_file :logo_image, styles: { medium: '200x90>', processors: %i[thumbnail compression] }, validate_media_type: false, default_url: ''
  has_attached_file :banner_image, styles: { small: '450x230>', processors: %i[thumbnail compression] }, validate_media_type: false, default_url: ''
  has_attached_file :banner_title_image, styles: { small: '200x90>', processors: %i[thumbnail compression] }, validate_media_type: false, default_url: ''
  has_attached_file :favicon, styles: { small: '40x40>', medium: '64x64>', processors: %i[thumbnail compression] }, validate_media_type: false, default_url: ''
  validates_attachment_content_type :favicon, content_type: %r[\Aimage\/(png|jpeg|jpg|x-icon|vnd.microsoft.icon)\z]
  validates_attachment_content_type :logo_image, :banner_image, content_type: %r[\Aimage\/(png|gif|jpeg|jpg)\z]
  accepts_nested_attributes_for :user
  scope :active_orgs, -> { where(status: true, hide_on_home: false) }
  scope :active_storage, -> { where(status: true, storage_type: :wasabi_storage.to_s) }
  before_save :update_default_values
  before_create :create_bucket
  after_save :update_solr, :update_resource_column_fields, :update_resource_search_column_fields, :update_resource_files_fields

  searchable do
    integer :id, stored: true
    integer :organization_organization_id, stored: false do
      id
    end
    text :organization_title, stored: false do
      name
    end
    string :name, stored: true
    text :description, stored: true
    string :url, stored: true
    boolean :organization_status, stored: false do
      status
    end
    boolean :status, stored: true
    string :document_type, stored: true do
      'organization'
    end
  end

  def update_default_values
    self.default_tab_selection = 2 if default_tab_selection.blank?
    self.title_font_color = '#ffffff' if title_font_color.blank?
    self.title_font_size = '28px' if title_font_size.blank?
  end

  def update_resource_column_fields
    columns_update = { number_of_column_fixed: '0',
                       columns_status:
                           { '0' => { value: 'id_ss', status: 'true' },
                             '1' => { value: 'title_ss', status: 'true' },
                             '2' => { value: 'collection_title', status: 'false' },
                             '3' => { value: 'resource_file_count_ss', status: 'false' },
                             '4' => { value: 'transcripts_count_ss', status: 'false' },
                             '5' => { value: 'indexes_count_ss', status: 'false' },
                             '6' => { value: 'updated_at_ss', status: 'false' },
                             '7' => { value: 'access_ss', status: 'false' },
                             '8' => { value: 'description_publisher_sms', status: 'false' },
                             '9' => { value: 'description_preferred_citation_ss', status: 'false' },
                             '10' => { value: 'description_language_sms', status: 'false' },
                             '11' => { value: 'description_identifier_sms', status: 'false' },
                             '12' => { value: 'description_duration_ss', status: 'false' },
                             '13' => { value: 'description_source_sms', status: 'false' },
                             '14' => { value: 'description_date_sms', status: 'false' },
                             '15' => { value: 'description_rights_statement_search_texts', status: 'false' },
                             '16' => { value: 'description_agent_sms', status: 'false' },
                             '17' => { value: 'description_coverage_sms', status: 'false' },
                             '18' => { value: 'description_description_search_texts', status: 'false' },
                             '19' => { value: 'description_format_sms', status: 'false' },
                             '20' => { value: 'description_source_metadata_uri_ss', status: 'false' },
                             '21' => { value: 'description_relation_sms', status: 'false' },
                             '22' => { value: 'description_subject_sms', status: 'false' },
                             '23' => { value: 'description_keyword_sms', status: 'false' },
                             '24' => { value: 'description_type_sms', status: 'false' },
                             '25' => { value: 'custom_unique_identifier_ss', status: 'false' } } }.to_json

    update(resource_table_column_detail: columns_update) if resource_table_column_detail.blank?
  end

  def update_resource_search_column_fields
    columns_update = {
      '0' => { value: 'id_ss', status: 'true' },
      '1' => { value: 'title_ss', status: 'true' },
      '2' => { value: 'collection_title', status: 'true' },
      '3' => { value: 'transcript', status: 'true' },
      '4' => { value: 'index', status: 'true' },
      '5' => { value: 'description_publisher_search_texts', status: 'true' },
      '6' => { value: 'description_preferred_citation_search_texts', status: 'true' },
      '7' => { value: 'description_language_search_texts', status: 'true' },
      '8' => { value: 'description_identifier_search_texts', status: 'true' },
      '9' => { value: 'description_source_search_texts', status: 'true' },
      '11' => { value: 'description_rights_statement_search_texts', status: 'true' },
      '12' => { value: 'description_agent_search_texts', status: 'true' },
      '13' => { value: 'description_format_search_texts', status: 'true' },
      '14' => { value: 'description_coverage_search_texts', status: 'true' },
      '15' => { value: 'description_description_search_texts', status: 'true' },
      '16' => { value: 'description_source_metadata_uri_search_texts', status: 'true' },
      '17' => { value: 'description_relation_search_texts', status: 'true' },
      '18' => { value: 'description_subject_search_texts', status: 'true' },
      '19' => { value: 'description_keyword_search_texts', status: 'true' },
      '20' => { value: 'description_type_search_texts', status: 'true' },
      '21' => { value: 'custom_unique_identifier_texts', status: 'true' }
    }.to_json
    update(resource_table_search_columns: columns_update) if resource_table_search_columns.blank?
  end

  def update_resource_files_fields
    display_columns_update = {
      number_of_column_fixed: '0',
      columns_status:
            {
              '0' => { status: 'true', value: 'id_is', sort_name: true },
              '1' => { status: 'true', value: 'resource_file_file_name_ss', sort_name: true },
              '2' => { status: 'true', value: 'access_ss', sort_name: true },
              '3' => { status: 'true', value: 'resource_file_content_type_ss', sort_name: true },
              '4' => { status: 'true', value: 'resource_file_file_size_ss', sort_name: true },
              '5' => { status: 'true', value: 'updated_at_ds', sort_name: true },
              '6' => { status: 'true', value: 'count_of_transcripts_ss', sort_name: true },
              '7' => { status: 'true', value: 'count_of_indexes_ss', sort_name: true },
              '8' => { status: 'true', value: 'collection_resource_id_ss', sort_name: true },
              '9' => { status: 'true', value: 'collection_resource_title_ss', sort_name: true },
              '10' => { status: 'true', value: 'thumbnail_ss', sort_name: false },
              '11' => { status: 'true', value: 'aviary_url_path_ss', sort_name: false },
              '12' => { status: 'true', value: 'aviary_purl_ss', sort_name: false },
              '13' => { status: 'true', value: 'player_embed_html_ss', sort_name: false },
              '14' => { status: 'true', value: 'media_embed_url_ss', sort_name: false },
              '15' => { status: 'true', value: 'resource_detail_embed_html_ss', sort_name: false },
              '16' => { status: 'true', value: 'target_domain_ss', sort_name: true },
              '17' => { status: 'true', value: 'file_display_name_ss', sort_name: true },
              '18' => { status: 'true', value: 'duration_ss', sort_name: true },
              '19' => { status: 'true', value: 'created_at_ds', sort_name: true }
            }
    }.to_json

    search_columns_update = {
      '0' => { status: 'true', value: 'id_is' },
      '1' => { status: 'true', value: 'resource_file_file_name_ss' },
      '2' => { status: 'true', value: 'resource_file_content_type_ss' },
      '3' => { status: 'true', value: 'collection_resource_title_ss' },
      '4' => { status: 'true', value: 'target_domain_ss' }
    }.to_json
    update(resource_file_display_column: display_columns_update, resource_file_search_column: search_columns_update) if resource_file_display_column.blank?
  end

  def update_solr
    Sunspot.index self
    Sunspot.commit
  end

  def validate_url
    if url.present?
      errors.add :url, 'only alphabets allowed.' unless url =~ /^[a-z0-9]+$/
      errors.add :url, 'not allowed. Please choose another' if %w[www staging edge get].include?(url)
    end
    true
  end

  def create_bucket
    bucket_exist = proc do |url|
      self.class.where(bucket_name: url).first
    end
    bucket_name = ENV['WASABI_PREFIX'] + '_' + url

    1.step do |i|
      break unless bucket_exist.call(bucket_name).present?
      bucket_name = bucket_name + '_' + i.to_s
    end

    if ENV['RAILS_ENV'] == 'production'
      s3 = s3_client
      s3.create_bucket(bucket: bucket_name)
      begin
        activate_bucket_logging(s3)
      rescue StandardError => e
        Rails.logger.error e.message
      end
    end
    self.bucket_name = bucket_name
  rescue StandardError
    raise 'There is an error in creating organization please contact Aviary admin'
  end

  def s3_client
    Aws::S3::Client.new(
      access_key_id: ENV['WASABI_KEY'],
      secret_access_key: ENV['WASABI_SECRET'],
      region: ENV['WASABI_REGION'],
      endpoint: ENV['WASABI_ENDPOINT']
    )
  end

  def activate_bucket_logging(s3_client)
    s3_client.put_bucket_logging(bucket: bucket_name,
                                 bucket_logging_status: {
                                   logging_enabled: { target_bucket: 'loggingaviaryaccess',
                                                      target_grants: [{
                                                        grantee: {
                                                          type: 'Group',
                                                          uri: 'http://acs.amazonaws.com/groups/global/AllUsers'
                                                        },
                                                        permission: 'FULL_CONTROL'
                                                      }],
                                                      target_prefix: "#{bucket_name}/" }
                                 })
  end

  def organization_owners
    organization_users.where(role_id: Role.org_owner_id)
  end

  def organization_admins
    organization_users.where(role_id: Role.org_admin_id)
  end

  def current_user_org_owner(user)
    organization_users.where(role_id: Role.org_owner_id, user_id: user.id)
  end

  def resource_count
    count = CollectionResource.select('COUNT(collection_resources.id) total')
                              .joins('INNER JOIN collections ON collections.id = collection_resources.collection_id AND collections.status != 0')
                              .joins('INNER JOIN organizations ON collections.organization_id = organizations.id')
                              .where('organizations.id = ? ', id).first
    count.present? ? count.total : 0
  end
end
