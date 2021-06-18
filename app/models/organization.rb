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
  after_save :update_solr, :update_resource_column_fields, :update_resource_search_column_fields, :update_resource_files_fields, :update_search_configuration

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

  def update_resource_column_fields(force_update = false, refresh_entry = false)
    return if resource_table_column_detail.present? && !force_update && !refresh_entry
    resource_table_column = { '0' => { value: 'id_ss', status: 'true' },
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
                              '25' => { value: 'custom_unique_identifier_ss', status: 'false' } }
    fixed_number_of_column = '0'
    if resource_table_column_detail.blank? || refresh_entry
      columns_status = resource_table_column
    else
      json_response = JSON.parse(resource_table_column_detail)
      fixed_number_of_column = 0
      columns_status = json_response['columns_status']
      total_columns = columns_status.count
      columns_status = add_missing_column(total_columns, resource_table_column, columns_status.to_h)
    end
    total_columns = columns_status.count
    columns_status = custom_fields_manager(columns_status, total_columns)
    columns_update = { number_of_column_fixed: fixed_number_of_column, columns_status: columns_status }.to_json
    update(resource_table_column_detail: columns_update)
  end

  def self.field_list_with_options
    {
      organization_id_is: { key: 'organization_id_is', label: 'Organization Name', single: false, helper_method: :render_organization_facet_value, tag: 'organization_id_is-tag', ex: 'organization_id_is-tag', type: 'integer' },
      collection_id_is: { key: 'collection_id_is', label: 'Collection Title', single: false, helper_method: :render_collection_facet_value, tag: 'collection_id_is-tag', ex: 'collection_id_is-tag', type: 'integer' },
      description_date_search_lms: { key: 'description_date_search_lms', label: 'Date', partial: 'blacklight_range_limit/range_limit_panel', range: { segments: false },
                                     tag: 'description_date_search_lms-tag', ex: 'description_date_search_lms-tag', type: 'date' },
      description_language_search_facet_sms: { key: 'description_language_search_facet_sms', label: 'Resource Language', single: false, type: 'text' },
      description_coverage_search_facet_sms: { key: 'description_coverage_search_facet_sms', label: 'Location', single: false, type: 'text' },
      has_transcript_ss: { key: 'has_transcript_ss', label: 'Has Transcript', single: false, type: 'text' },
      has_index_ss: { key: 'has_index_ss', label: 'Has Index', single: false, type: 'text' },
      description_format_search_facet_sms: { key: 'description_format_search_facet_sms', label: 'Format', single: false, type: 'text' },
      description_publisher_search_facet_sms: { key: 'description_publisher_search_facet_sms', label: 'Publisher', single: false, type: 'text' },
      description_agent_search_facet_sms: { key: 'description_agent_search_facet_sms', label: 'Agent', single: false, type: 'text' },
      description_keyword_search_facet_sms: { key: 'description_keyword_search_facet_sms', label: 'Keyword', single: false, type: 'text' },
      description_subject_search_facet_sms: { key: 'description_subject_search_facet_sms', label: 'Subject', single: false, type: 'text' },
      description_type_search_facet_sms: { key: 'description_type_search_facet_sms', label: 'Type', single: false, type: 'text' },
      access_ss: { key: 'access_ss', label: 'Access', single: false, type: 'text' },
      description_duration_ls: { key: 'description_duration_ls', label: 'Duration', single: true, partial: 'blacklight_range_limit/range_limit_panel',
                                 range: { segments: false }, tag: 'description_duration_ls', ex: 'description_duration_ls-tag', type: 'date' }
    }
  end

  def custom_fields_manager(columns_status, total_columns)
    return columns_status if Rails.env.test? || collections.blank?
    collections.each do |single_field|
      next unless single_field.all_fields['CollectionResource'].present?
      single_field.all_fields['CollectionResource'].each do |single|
        if single['field'].is_custom
          type = Aviary::SolrIndexer.field_type_finder(single['field'].fetch_type)
          type = '_sms' if single['field'].fetch_type == 'date'
          custom_field_values = 'custom_field_values_' + single['field'].system_name + type
          add_value = true
          columns_status.each do |single_columns_status|
            if [single_columns_status.second[:value], single_columns_status.second['value']].include? custom_field_values
              add_value = false
              break
            end
          end
          columns_status[total_columns.to_s] = { value: custom_field_values, status: 'false' } if add_value
          total_columns += 1
        end
      end
    end
    columns_status
  end

  def add_missing_column(total_columns, default_columns, added_columns)
    new_columns = []
    default_columns.each do |single_default_columns|
      add_value = true
      added_columns.each do |single_added_column|
        if single_default_columns.second[:value] == single_added_column.second['value']
          add_value = false
          break
        end
      end
      new_columns << { value: single_default_columns.second[:value], status: 'false' } if add_value
    end
    new_columns.each do |single_new_column|
      added_columns[total_columns] = single_new_column
      total_columns += 1
    end
    added_columns
  end

  def update_resource_search_column_fields(force_update = false, refresh_entry = false)
    return if resource_table_search_columns.present? && !force_update && !refresh_entry
    table_search_columns = {
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
    }

    columns_update = if resource_table_search_columns.blank? || refresh_entry
                       table_search_columns
                     else
                       columns_update = JSON.parse(resource_table_search_columns)
                       total_columns = columns_update.count
                       add_missing_column(total_columns, table_search_columns, columns_update.to_h)
                     end
    total_columns = columns_update.count
    columns_update = custom_fields_manager(columns_update, total_columns)
    update(resource_table_search_columns: columns_update.to_json)
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
              '19' => { status: 'true', value: 'created_at_ds', sort_name: true },
              '20' => { status: 'true', value: 'collection_title_text', sort_name: true }
            }
    }.to_json

    search_columns_update = {
      '0' => { status: 'true', value: 'id_is' },
      '1' => { status: 'true', value: 'resource_file_file_name_ss' },
      '2' => { status: 'true', value: 'resource_file_content_type_ss' },
      '3' => { status: 'true', value: 'collection_resource_title_ss' },
      '4' => { status: 'true', value: 'target_domain_ss' },
      '5' => { status: 'true', value: 'collection_title_text', sort_name: true }
    }.to_json
    update(resource_file_display_column: display_columns_update, resource_file_search_column: search_columns_update) if resource_file_display_column.blank?
  end

  def update_search_configuration(force_update = false)
    if search_facet_fields.present? && force_update
      dynamic_fields = JSON.parse(search_facet_fields)
      total_fields = dynamic_fields.count
      new_fields = []
      all_org_fields.each do |_key, db_fields|
        current_field = db_fields['key']
        flag_add_field = true
        dynamic_fields.each do |_key, custom_field_managed|
          if current_field == custom_field_managed['key']
            flag_add_field = false
            break
          end
        end
        new_fields << db_fields if flag_add_field
      end
      if new_fields.present?
        new_fields.each do |single_field|
          dynamic_fields[total_fields] = single_field
          total_fields += 1
        end
      end
      update(search_facet_fields: dynamic_fields.to_json)
    elsif search_facet_fields.blank?
      update(search_facet_fields: all_org_fields.to_json)
    end
  end

  def detect_search_facets_change
    dynamic_fields = JSON.parse(search_facet_fields)
    remove_fields_list = []
    dynamic_fields.each do |key_outer, custom_field_managed|
      field_exists_flag = false
      all_org_fields.each do |_key, db_fields|
        field_exists_flag = true if custom_field_managed['key'] == db_fields['key']
      end
      remove_fields_list << key_outer unless field_exists_flag
    end
    remove_fields_list.each do |single_key|
      dynamic_fields = dynamic_fields.except(single_key.to_s)
    end
    counter = 0
    updated_dynamic_fields = {}
    dynamic_fields.each do |_key, custom_field_managed|
      collection_ids = []
      unless custom_field_managed['is_default_field']
        collections.each do |collection_fields|
          collection_fields.all_fields['CollectionResource'].each do |single_field|
            if CustomFields::Field::TypeInformation.fetch_type(single_field['field'].column_type).to_s != 'editor' && custom_field_managed['key'] == single_field['field'].system_name
              collection_ids << collection_fields.id
            end
          end
        end
      end

      custom_field_managed['collection'] = collection_ids.uniq.join(',')
      updated_dynamic_fields[counter.to_s] = custom_field_managed
      counter += 1
    end
    update(search_facet_fields: updated_dynamic_fields.to_json)
  end

  def all_org_fields
    dynamic_fields = {}
    all_ready_added = {}
    skip_fields = %w[format subject type location date language identifier relation source_metadata_uri coverage source publisher agent keyword duration title]
    counter = 0
    Organization.field_list_with_options.each do |_key, single_field_list|
      next if single_field_list[:key] == 'organization_id_is'
      type = single_field_list[:type]
      sys_name = single_field_list[:key]
      dynamic_fields[counter] = { 'key' => sys_name, 'label' => single_field_list[:label], 'type' => type, 'status' => true, 'is_default_field' => true }
      counter += 1
    end
    return dynamic_fields if Rails.env.test? || collections.blank?
    collections.each do |collection_fields|
      collection_fields.all_fields['CollectionResource'].each do |single_field|
        type = CustomFields::Field::TypeInformation.fetch_type(single_field['field'].column_type).to_s
        sys_name = single_field['field'].system_name
        if type != 'editor' && !skip_fields.include?(sys_name)
          collection_title = ''
          collection_title = collection_fields.title if single_field['field'].is_custom

          if all_ready_added[sys_name].blank?
            dynamic_fields[counter] = { 'key' => sys_name, 'label' => single_field['field'].label, 'type' => type, 'status' => false, 'is_default_field' => false, 'collection' => collection_title }
            all_ready_added[sys_name] = counter
            counter += 1
          elsif collection_title.present?
            dynamic_fields[all_ready_added[sys_name]]['collection'] += ' , ' + collection_title
          end
        end
      end
    end
    dynamic_fields
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

  def update_field_settings
    update_resource_search_column_fields(true)
    update_resource_column_fields(true)
    update_search_configuration(true)
    detect_search_facets_change
  end

  def update_file_index_fields
    display_columns_update = {
      number_of_column_fixed: '0',
      columns_status:
        {
          '0' => { status: 'true', value: 'id_is', sort_name: true },
          '1' => { status: 'true', value: 'title_ss', sort_name: true },
          '2' => { status: 'true', value: 'is_public_ss', sort_name: true },
          '3' => { status: 'true', value: 'language_ss', sort_name: true },
          '4' => { status: 'true', value: 'description_ss', sort_name: true },
          '5' => { status: 'true', value: 'updated_at_ds', sort_name: true },
          '6' => { status: 'true', value: 'created_at_ds', sort_name: true },
          '7' => { status: 'true', value: 'file_display_name_ss', sort_name: true },
          '8' => { status: 'true', value: 'collection_resource_title_ss', sort_name: true }
        }
    }.to_json

    search_columns_update = {
      '0' => { status: 'true', value: 'id_is' },
      '1' => { status: 'true', value: 'title_ss', sort_name: true },
      '2' => { status: 'true', value: 'is_public_ss', sort_name: true },
      '3' => { status: 'true', value: 'language_ss', sort_name: true },
      '4' => { status: 'true', value: 'description_ss', sort_name: true },
      '5' => { status: 'true', value: 'file_display_name_ss', sort_name: true },
      '6' => { status: 'true', value: 'collection_resource_title_ss', sort_name: true }
    }.to_json
    update(file_index_display_column: display_columns_update, file_index_search_column: search_columns_update) if file_index_display_column.blank?
  end

  def update_transcript_fields
    display_columns_update = {
      number_of_column_fixed: '0',
      columns_status:
        {
          '0' => { status: 'true', value: 'id_is', sort_name: true },
          '1' => { status: 'true', value: 'title_ss', sort_name: true },
          '2' => { status: 'true', value: 'is_public_ss', sort_name: true },
          '3' => { status: 'true', value: 'language_ss', sort_name: true },
          '4' => { status: 'true', value: 'description_ss', sort_name: true },
          '5' => { status: 'true', value: 'updated_at_ds', sort_name: true },
          '6' => { status: 'true', value: 'created_at_ds', sort_name: true },
          '7' => { status: 'true', value: 'file_display_name_ss', sort_name: true },
          '8' => { status: 'true', value: 'collection_resource_title_ss', sort_name: true }
        }
    }.to_json

    search_columns_update = {
      '0' => { status: 'true', value: 'id_is' },
      '1' => { status: 'true', value: 'title_ss', sort_name: true },
      '2' => { status: 'true', value: 'is_public_ss', sort_name: true },
      '3' => { status: 'true', value: 'language_ss', sort_name: true },
      '4' => { status: 'true', value: 'description_ss', sort_name: true },
      '5' => { status: 'true', value: 'file_display_name_ss', sort_name: true },
      '6' => { status: 'true', value: 'collection_resource_title_ss', sort_name: true }
    }.to_json
    update(transcript_display_column: display_columns_update, transcript_search_column: search_columns_update) if transcript_display_column.blank?
  end
end
