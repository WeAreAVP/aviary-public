# Collection Resource Resource|Asset
class CollectionResource < ApplicationRecord
  attr_accessor :can_edit, :can_view
  include Aviary::SolrIndexer

  belongs_to :collection, counter_cache: ENV['RAILS_ENV'] == 'test' ? false : true
  has_many :playlist_resources, dependent: :destroy
  has_many :playlist_items, dependent: :destroy
  has_many :collection_resource_files, dependent: :destroy
  validates :noid, uniqueness: { message: 'PURL already taken.' }
  validate :unique_custom_unique_identifier
  accepts_nested_attributes_for :collection_resource_files, reject_if: :all_blank, allow_destroy: true
  attr_accessor :tab_resource_file, :sort_order, :file_url, :embed_code, :embed_type, :target_domain, :trans_points_solr, :index_points_solr, :description_values_solr, :collection_values_solr, :resource_file_id, :custom_description_solr
  scope :featured, -> { where(access: accesses[:access_public], is_featured: true) }
  scope :public_visible, -> { where(access: accesses[:access_public]) }
  enum access: %i[access_restricted access_public access_private]
  before_save :index_points_fetch, :transcript_points_fetch, :description_values_fetch, :update_attributes_solr
  before_create :generate_noid
  after_save :update_duration
  after_destroy :remove_from_solr
  after_create :update_resource_count
  before_update :updated_collection_name
  attr_accessor :meta_date_updated, :collection_resource_files_list, :file_indexes_list, :file_transcripts_list
  custom_fields?
  attr_accessor :dynamic_initializer

  def update_attributes_solr
    self.collection_resource_files_list = collection_resource_files
    self.file_indexes_list = collection_resource_files.map(&:file_indexes).flatten
    self.file_transcripts_list = collection_resource_files.map(&:file_transcripts).flatten
  end

  def init_dynamic_initializer
    if id.nil? && !has_attribute?('collection_id')
      self.collection_id = nil
    end
    @dynamic_initializer = {
      parent_entity: collection
    }
  end

  def updated_collection_name
    CollectionResource.bulk_edit_collection_operation(id, collection_id) if collection_id_changed? && meta_date_updated != 'updated'
    self.meta_date_updated = 'updated' if collection_id_changed? && meta_date_updated != 'updated'
    update(collection_id: collection_id_change.second) if collection_id_changed? && meta_date_updated != 'updated'
  end

  def unique_custom_unique_identifier
    return true unless custom_unique_identifier.present?
    query = CollectionResource.where(custom_unique_identifier: custom_unique_identifier, collection_id: collection.organization.collections.pluck(:id))
    query = query.where.not(id: id) if id.present?
    if query.present?
      errors.add(:custom_unique_identifier, '<span style="color: #c30">Given custom unique identifier is already taken</span>')
      return false
    end
    true
  end

  def update_resource_count
    organization = collection.organization
    count = collection.organization.used_resources.nil? ? organization.resource_count : collection.organization.used_resources + 1
    organization.update_attribute('used_resources', count)
  end

  def self.permission_group_columns
    { columns_status: { '0' => { value: 'title_ss', status: 'true' },
                        '1' => { value: 'id_is', status: 'true' },
                        '2' => { value: 'access_ss', status: 'true' },
                        '3' => { value: 'description_identifier_sms', status: 'true' },
                        '4' => { value: 'description_date_sms', status: 'true' } } }
  end

  def remove_from_solr
    Sunspot.remove_by_id(CollectionResource, id)
    Sunspot.commit
  end

  def update_duration
    duration = 0.0
    begin
      reload
      unless Rails.env.to_s.casecmp('test').zero?
        collection_resource_files.each do |single_file|
          duration += single_file.duration unless single_file.duration.blank?
        end
      end
      update_field_value('duration', [{ value: duration, vocab_value: '' }])
    rescue StandardError
      true
    end
  end

  searchable do
    solr_mapper_transcript_point = [{ text: :transcript_point_text }, { speaker: :transcript_point_speaker }, { title: :index_point_title }]
    solr_mapper_index_point = [{ title: :index_point_title }, { synopsis: :index_point_synopsis }, { subjects: :index_point_subjects },
                               { keywords: :index_point_keywords }, { partial_script: :index_point_partial_script }]
    solr_mapper_definition = [
      { 'title_search' => :description_title_search }, { 'publisher_search' => :description_publisher_search }, { 'rights_statement_search' => :description_rights_statement_search },
      { 'source_search' => :description_source_search }, { 'agent_search' => :description_agent_search }, { 'date_search' => :description_date_search }, { 'type' => :description_type },
      { 'coverage_search' => :description_coverage_search }, { 'language_search' => :description_language_search }, { 'description_search' => :description_description_search },
      { 'format_search' => :description_format_search }, { 'identifier_search' => :description_identifier_search }, { 'relation_search' => :description_relation_search },
      { 'subject_search' => :description_subject_search }, { 'keyword_search' => :description_keyword_search }, { 'type_search' => :description_type_search },
      { 'source_metadata_uri_search' => :description_source_metadata_uri_search }, { 'preferred_citation_search' => :description_preferred_citation_search },
      { 'custom_field_values_search' => :description_custom_field_values_search }, { 'duration_search' => :description_duration },
      { 'title' => :description_title }, { 'publisher' => :description_publisher }, { 'rights_statement' => :description_rights_statement }, { 'source' => :description_source },
      { 'date' => :description_date }, { 'coverage' => :description_coverage }, { 'language' => :description_language }, { 'description' => :description_description },
      { 'format' => :description_format }, { 'identifier' => :description_identifier }, { 'relation' => :description_relation }, { 'subject' => :description_subject },
      { 'keyword' => :description_keyword }, { 'agent' => :description_agent }, { 'preferred_citation' => :description_preferred_citation }, { 'duration' => :description_duration },
      { 'source_metadata_uri' => :description_source_metadata_uri }, { 'all_vocabs' => :description_vocabulary }
    ]
    integer :id, stored: true
    string :id, stored: true
    string :title, stored: true
    text :title, stored: false
    boolean :is_featured, stored: true
    boolean :access, stored: true

    string :access, multiple: false, stored: true do
      resource_has_restricted_file = access
      if resource_has_restricted_file.present? && collection_resource_files_list.present?
        collection_resource_files_list.each do |single_file|
          resource_has_restricted_file = 'public_resource_restricted_content' if access == 'access_public' && single_file.access == 'no'
        end
        index_transcripts_listing = [file_indexes_list, file_transcripts_list].flatten
        if resource_has_restricted_file != 'public_resource_restricted_content' && index_transcripts_listing.present?
          index_transcripts_listing.each do |single_file|
            resource_has_restricted_file = 'public_resource_restricted_content' if access == 'access_public' && !single_file.is_public
          end
        end
      end
      resource_has_restricted_file
    end

    boolean :status, stored: true

    string :external_resource_id, stored: true
    string :document_type, stored: true do
      'collection_resource'
    end
    string :created_at, stored: true
    string :updated_at, stored: true
    integer :collection_id, stored: true
    string :noid, multiple: false, stored: true
    text :custom_unique_identifier, stored: true
    string :custom_unique_identifier, stored: true
    integer :resource_collection_id, stored: false do
      collection_id
    end
    integer :resource_organization_id, stored: false do
      if collection.present?
        collection.organization_id
      else
        ''
      end
    end
    integer :organization_id, multiple: false, stored: true do
      if collection.present?
        collection.organization_id
      else
        ''
      end
    end
    # resource_file_file_name
    string :thumbnail_link, multiple: false, stored: true do
      if CollectionResourceFile.where(collection_resource_id: id).present?
        url = CollectionResourceFile.where(collection_resource_id: id).order('sort_order ASC').first.thumbnail.url
        url.present? ? url.gsub("'", "\\\\'") : "https://#{ENV['S3_HOST_CDN']}/public/images/video-default.png"
      else
        "https://#{ENV['S3_HOST_CDN']}/public/images/video-default.png"
      end
    end

    string :transcripts_count, multiple: false, stored: true do
      collection_resource_files = CollectionResourceFile.where(collection_resource_id: id)
      count = 0
      if collection_resource_files.present?
        collection_resource_files.each do |single_file|
          count += single_file.file_transcripts.size
        end
      end
      count
    end

    string :indexes_count, multiple: false, stored: true do
      collection_resource_files = CollectionResourceFile.where(collection_resource_id: id)
      count = 0
      if collection_resource_files.present?
        collection_resource_files.each do |single_file|
          count += single_file.file_indexes.size
        end
      end
      count
    end

    string :resource_file_count, multiple: false, stored: true do
      CollectionResourceFile.where(collection_resource_id: id).present? ? CollectionResourceFile.where(collection_resource_id: id).size : 0
    end

    string :has_transcript, multiple: false, stored: true do
      !trans_points_solr.nil? && !trans_points_solr.empty? && !trans_points_solr[:text].empty? ? 'Yes' : 'No'
    end
    string :has_index, multiple: false, stored: true do
      !index_points_solr.nil? && !index_points_solr.empty? && !index_points_solr[:title].empty? ? 'Yes' : 'No'
    end

    solr_mapper_transcript_point.each do |single_mapper_definition|
      text single_mapper_definition[single_mapper_definition.keys.first], stored: true do
        trans_points_solr[single_mapper_definition.keys.first] if !trans_points_solr.nil? && trans_points_solr.key?(single_mapper_definition.keys.first)
      end
    end
    solr_mapper_index_point.each do |single_mapper_definition|
      text single_mapper_definition[single_mapper_definition.keys.first], stored: true do
        index_points_solr[single_mapper_definition.keys.first] if !index_points_solr.nil? && index_points_solr.key?(single_mapper_definition.keys.first)
      end
    end
    solr_mapper_definition.each do |single_mapper_definition|
      multiple = true
      multiple = false if %w[source_metadata_uri_search preferred_citation_search source_metadata_uri preferred_citation duration].include? single_mapper_definition.keys.first
      if %i[description_rights_statement description_description].include?(single_mapper_definition[single_mapper_definition.keys.first])
        text single_mapper_definition[single_mapper_definition.keys.first], stored: true do
          description_values_solr[single_mapper_definition.keys.first] if !description_values_solr.nil? && description_values_solr.key?(single_mapper_definition.keys.first) && !single_mapper_definition.keys.first.include?('_search')
        end
      else
        string single_mapper_definition[single_mapper_definition.keys.first], multiple: multiple, stored: true do
          if multiple
            description_values_solr[single_mapper_definition.keys.first] if !description_values_solr.nil? && description_values_solr.key?(single_mapper_definition.keys.first) && !single_mapper_definition.keys.first.include?('_search')
          elsif !description_values_solr.nil? && description_values_solr.key?(single_mapper_definition.keys.first) && !single_mapper_definition.keys.first.include?('_search')
            description_values_solr[single_mapper_definition.keys.first].first
          end
        end
      end
      if single_mapper_definition.keys.first == 'date_search'
        long single_mapper_definition[single_mapper_definition.keys.first], multiple: true, stored: true do
          description_values_solr[single_mapper_definition.keys.first] if !description_values_solr.nil? && description_values_solr.key?(single_mapper_definition.keys.first) && single_mapper_definition.keys.first.include?('_search')
        end
      elsif single_mapper_definition.keys.first == 'duration_search'
        long single_mapper_definition[single_mapper_definition.keys.first], multiple: false, stored: true do
          description_values_solr[single_mapper_definition.keys.first].first if !description_values_solr.nil? && description_values_solr.key?(single_mapper_definition.keys.first) && single_mapper_definition.keys.first.include?('_search')
        end
      else
        if %i[description_rights_statement description_description description_rights_statement_search description_description_search].include?(single_mapper_definition[single_mapper_definition.keys.first])
          text single_mapper_definition[single_mapper_definition.keys.first].to_s + '_facet', stored: true do
            description_values_solr[single_mapper_definition.keys.first] if !description_values_solr.nil? && description_values_solr.key?(single_mapper_definition.keys.first) && single_mapper_definition.keys.first.include?('_search')
          end
          string single_mapper_definition[single_mapper_definition.keys.first].to_s, multiple: true, stored: true do
            text_search_handler_all = []
            unless description_values_solr[single_mapper_definition.keys.first].blank?
              description_values_solr[single_mapper_definition.keys.first].each do |single_description_string|
                text_search_handler = single_description_string.gsub(/(.{300}\S*)\s*/, '\\1||||||')
                text_search_handler = text_search_handler.split('||||||')
                text_search_handler_all << text_search_handler if text_search_handler.present?
              end
            end
            if text_search_handler_all.blank?
              text_search_handler_all = description_values_solr[single_mapper_definition.keys.first]
            end
            text_search_handler_all.present? ? text_search_handler_all.flatten : ''
          end
        else
          string single_mapper_definition[single_mapper_definition.keys.first].to_s + '_facet', multiple: multiple, stored: true do
            if multiple
              description_values_solr[single_mapper_definition.keys.first] if !description_values_solr.nil? && description_values_solr.key?(single_mapper_definition.keys.first) && single_mapper_definition.keys.first.include?('_search')
            elsif !description_values_solr.nil? && description_values_solr.key?(single_mapper_definition.keys.first) && single_mapper_definition.keys.first.include?('_search')
              description_values_solr[single_mapper_definition.keys.first].first
            end
          end
        end
        text single_mapper_definition[single_mapper_definition.keys.first], stored: true do
          description_values_solr[single_mapper_definition.keys.first] if single_mapper_definition.keys.first.include?('_search')
        end
      end
    end
  end

  def resource_field_info_update(params)
    collection_resource_field_values.where(collection_resource_id: id).delete_all
    flag = collection_resource_field_values.create(params)
    update_duration
    flag
  end

  def delete_resource_files(params)
    collection_resource_files.destroy(params[:resource_file_id])
  end

  def tombstone_fields
    custom_fields = all_fields
    tombstone_fields = custom_fields['tombstones']
    if tombstone_fields.length.zero?
      custom_fields['CollectionResource'].each do |cfield|
        if %w[agent date duration].include? cfield['field'].system_name
          tombstone_fields << cfield
        end
      end
    end
    fields = []
    tombstone_fields.each do |single_field|
      fields << single_field['field'].system_name
    end
    fields
  end

  def self.limit_response
    10
  end

  def self.remove_unwanted_search_chars(single_query)
    single_query = single_query.gsub(%r{[\/\\()|'"*:^~`{}]}, '')
    single_query = single_query.gsub(/]/, '')
    single_query.delete '['
  end

  def self.search_perp(query, field)
    limiter = ''
    if query.present?
      if query.include?(' ')
        query_raw = query.split(' ')
        limiter_inner = []
        query_raw.each do |single_query|
          single_query = remove_unwanted_search_chars(single_query)
          limiter_inner << "#{field}:*#{single_query}*"
        end
        limiter = " ( #{limiter_inner.join(' AND ')}) "
      else
        query = remove_unwanted_search_chars(query)
        limiter = "#{field}:*#{query}*"
      end
    end
    limiter
  end

  def self.straight_search_perp(query, field)
    limiter = ''
    if query.present?
      if query.include?(' ')
        query_raw = query.split(' ')
        limiter_inner = []
        query_raw.each do |single_query|
          single_query = remove_unwanted_search_chars(single_query)
          limiter_inner << "#{field}:\"#{single_query}\""
        end
        limiter = " ( #{limiter_inner.join(' AND ')}) "
      else
        query = remove_unwanted_search_chars(query)
        limiter = "#{field}:\"#{query}\""
      end
    end
    limiter
  end

  def self.fetch_collections(export_and_current_organization, solr)
    collections_raw = solr.get 'select', params: { q: '*:*',  start: 0, rows: 1000, fq: ['document_type_ss:collection', 'status_ss:active', "organization_id_is:#{export_and_current_organization[:current_organization].id}"], fl: %w[id_is title_ss] }
    collections = {}
    collections_raw['response']['docs'].each do |single_collection|
      collections[single_collection['id_is'].to_s] = single_collection['title_ss']
    end
    collections
  end

  def self.solr_path
    ENV['SOLR_URL'].blank? ? "http://127.0.0.1:8983/solr/#{Rails.env}" : ENV['SOLR_URL']
  end

  def self.solr_connect
    RSolr.connect url: solr_path
  end

  def self.fetch_resources(page, per_page, sort_column, sort_direction, params, limit_condition, export_and_current_organization = { export: false, current_organization: false, called_from: '' })
    q = params[:search][:value] if params.present?
    solr = solr_connect
    solr_url = solr_path
    select_url = "#{solr_url}/select"
    limiter = []
    solr_q_condition = '*:*'
    complex_phrase_def_type = false
    fq_filters = ' document_type_ss:collection_resource  '
    if q.present? && q.match(/([\w]+\.)+[\w]+(?=[\s]|$)/).present?
      # for this kind of pattern (hvt.1021.232)
      solr_q_condition = "keywords:\"#{q}\""
      complex_phrase_def_type = true
    elsif q.present?
      counter = 0
      fq_filters_inner = ''
      search_columns = JSON.parse(export_and_current_organization[:current_organization][:resource_table_search_columns])
      if export_and_current_organization[:called_from] == 'permission_group'
        search_columns = { '0' => { 'value' => 'id_ss', 'status' => 'true' },
                           '1' => { 'value' => 'title_text', 'status' => 'true' },
                           '2' => { 'value' => 'description_identifier_search_texts', 'status' => 'true' } }
      end
      search_columns.each do |_, value|
        if value['status'] == 'true'
          case value['value']
          when 'index'
            SearchBuilder.index_search_fields.each do |single_field_index|
              fq_filters_inner = fq_filters_inner + (counter != 0 ? ' OR ' : ' ') + " #{search_perp(q, single_field_index.to_s)} "
            end
          when 'transcript'
            SearchBuilder.transcript_search_fields.each do |single_field_transcript|
              fq_filters_inner = fq_filters_inner + (counter != 0 ? ' OR ' : ' ') + " #{search_perp(q, single_field_transcript.to_s)} "
            end
          when 'collection_title'
            # if limit is organization then let it go but if limit is collection_is then change it to id_is to only get that specific collection
            fq_filters_inner, counter = CollectionResource.search_collection_column(limit_condition, solr, q, counter, fq_filters_inner)
          when 'id_ss', 'title_ss', 'id_is', 'title_text', 'custom_unique_identifier_texts', 'custom_unique_identifier_ss'
            fq_filters_inner += simple_field_search_handler(value, fq_filters_inner, counter, q)
            if value['value'] == 'title_ss'
              alter_search_new = 'title_text'
              fq_filters_inner += " OR  #{search_perp(q, alter_search_new)} "
              fq_filters_inner += " OR  #{straight_search_perp(q, alter_search_new)} "
            end
          when 'description_agent_search_texts', 'description_coverage_search_texts', 'description_description_search_texts', 'description_identifier_search_texts', 'description_keyword_search_texts',
            'description_language_search_texts', 'description_preferred_citation_search_texts', 'description_publisher_search_texts', 'description_relation_search_texts', 'description_rights_statement_search_texts',
            'description_source_metadata_uri_search_texts', 'description_source_search_texts', 'description_subject_search_texts', 'description_title_search_texts', 'description_type_search_texts', 'description_format_search_texts'
            fq_filters_inner = fq_filters_inner + (counter != 0 ? ' OR ' : ' ') + " #{search_perp(q, value['value'])} "
            alter_search = value['value'].clone
            alter_search_wildcard = value['value'].clone
            if !%w[description_rights_statement_search_texts description_description_search_texts title_ss].include?(alter_search)
              alter_search = if %w[description_source_metadata_uri_search_texts description_preferred_citation_search_texts].include?(alter_search)
                               alter_search.sub! '_search_texts', '_facet_ss'
                               alter_search_wildcard.sub! '_search_texts', '_ss'
                             else
                               alter_search.sub! '_search_texts', '_facet_sms'
                               alter_search_wildcard.sub! '_search_texts', '_sms'
                             end
              fq_filters_inner += " OR  #{search_perp(q, alter_search)} "
              fq_filters_inner += " OR  #{straight_search_perp(q, alter_search)} "
              fq_filters_inner += " OR  #{search_perp(q, alter_search_wildcard)} "
              fq_filters_inner += " OR  #{straight_search_perp(q, alter_search_wildcard)} "
            elsif %w[description_rights_statement_search_texts description_description_search_texts].include?(alter_search_wildcard)
              alter_search_wildcard_string = alter_search_wildcard.clone
              alter_search_wildcard.sub! '_search_texts', '_search_facet_texts'
              fq_filters_inner += " OR  #{search_perp(q, alter_search_wildcard)} "
              fq_filters_inner += " OR  #{straight_search_perp(q, alter_search_wildcard)} "
              alter_search_wildcard_string.sub! '_search_texts', '_search_sms'
              fq_filters_inner += " OR  #{straight_search_perp(q, alter_search_wildcard_string)} "
            end
          when ->(search_key) { search_key.include?('custom_field_values_') }
            alter_search = value['value'].clone
            alter_search_new = alter_search.sub(/.*\K_sms/, '_texts') unless alter_search.include?('_lms') && alter_search.include?('_text')

            fq_filters_inner += " OR  #{search_perp(q, alter_search)} "
            fq_filters_inner += " OR  #{straight_search_perp(q, alter_search)} "

            fq_filters_inner += " OR  #{search_perp(q, alter_search_new)} "
            fq_filters_inner += " OR  #{straight_search_perp(q, alter_search_new)} "
          end
          counter += 1
        end
      end
      fq_filters += " AND (#{fq_filters_inner}) " unless fq_filters_inner.blank?
    end
    limiter << limit_condition
    collections = fetch_collections(export_and_current_organization, solr)
    filters = ['-{!join from=collection_collection_id_i to=resource_collection_id_i}status_ss:deleted']
    filters << fq_filters
    filters << limiter
    query_params = { q: solr_q_condition, fq: filters.flatten }
    query_params[:defType] = 'complexphrase' if complex_phrase_def_type
    query_params[:wt] = 'json'
    total_response = Curl.post(select_url, query_params)
    begin
      total_response = JSON.parse(total_response.body_str)
    rescue StandardError
      total_response = { 'response' => { 'numFound' => 0 } }
    end
    sort_column = 'collection_id_is' if sort_column.to_s == 'collection_title'
    query_params[:sort] = "#{sort_column} #{sort_direction}" if sort_column.present? && sort_direction.present?
    if export_and_current_organization[:export]
      query_params[:start] = 0
      query_params[:rows] = 100_000_000
    else
      query_params[:start] = (page - 1) * per_page
      query_params[:rows] = per_page
    end
    response = Curl.post(select_url, query_params)
    begin
      response = JSON.parse(response.body_str)
    rescue StandardError
      response = { 'response' => { 'docs' => {} } }
    end

    count = total_response['response']['numFound'].to_i
    [response['response']['docs'], count, collections, export_and_current_organization[:current_organization]]
  end

  def self.simple_field_search_handler(value, fq_filters_inner, counter, query)
    alter_search = value['value']
    fq_filters_inner += fq_filters_inner + (counter != 0 ? ' OR ' : ' ') + " #{search_perp(query, value['value'])} "
    fq_filters_inner += " OR  #{alter_search}:#{query}"
    fq_filters_inner += " OR  #{straight_search_perp(query, alter_search)} "
    fq_filters_inner
  end

  def generate_noid
    service = Noid::Rails::Service.new
    self.noid = service.mint
  end

  def self.bulk_edit_collection_operation(single_resource_id, collections)
    resource = CollectionResource.find_by_id(single_resource_id)
    resource_fields = resource.all_fields['CollectionResource']
    assigned_col = Collection.find_by_id(collections)
    col_fields = assigned_col.dynamic_attributes['settings']['CollectionResource']
    updated_values = []
    resource_fields.each do |field|
      field_index = nil
      col_fields.each do |col_field|
        db_field = CustomFields::Field.find(col_field['field_id'])
        if field['field'].id == col_field['field_id'].to_i
          field_index = field['field'].id
          break
        elsif field['field'].system_name == db_field.system_name && field['field'].column_type == db_field.column_type && field['field'].source_type == db_field.source_type
          field_index = db_field.id
          break
        end
      end
      row = {}
      if field_index.nil?
        new_field =
          {
            label: field['field'].label, system_name: field['field'].system_name, is_vocabulary: field['field'].is_vocabulary,
            vocabulary: field['field'].vocabulary, column_type: field['field'].column_type, dropdown_options: field['field'].dropdown_options, default: field['field'].default,
            help_text: field['field'].help_text, source_type: field['field'].source_type, is_required: field['field'].is_required, is_repeatable: field['field'].is_repeatable,
            is_public: field['field'].is_public, is_custom: field['field'].is_custom
          }
        field_id = assigned_col.create_update_dynamic(new_field, nil, field['settings'])
        row['field_id'] = field_id
      else
        row['field_id'] = field_index
      end
      row['values'] = field['values']
      updated_values << row
    end
    resource.batch_update_values(updated_values, true)
  end

  def self.list_resources(organization, collection_id, query_condition, is_featured, limit, order_by = 'RAND()', offset = false)
    order_by = order_by.gsub('RAND()', 'RANDOM()') if Rails.env.test?
    query = 'SELECT collection_resources.* '
    query += ' FROM `collection_resources` '
    query += ' INNER JOIN `collections` ON `collections`.`id` = `collection_resources`.`collection_id` AND collections.status != 0 '
    query += ' INNER JOIN `organizations` ON `organizations`.`id` = `collections`.`organization_id` '
    query += ' LEFT OUTER JOIN `collection_resource_files` ON `collection_resource_files`.`collection_resource_id` = `collection_resources`.`id` '
    query += ' WHERE (`collection_resource_files`.`collection_resource_id` IS NOT NULL) '
    query += ' AND `organizations`.`status` = 1 '
    query += " AND `organizations`.`id` = #{organization.id}" if organization.present?
    query += " AND #{query_condition}" if query_condition.present?
    query += ' AND collection_resources.is_featured = 1' if is_featured.present?
    query += " AND `collection_resources`.`collection_id` = #{collection_id}" if collection_id.present?
    query += " GROUP BY collection_resources.id ORDER BY #{order_by}"
    query += " LIMIT #{limit} "
    query += " OFFSET #{offset}" if offset.present?
    CollectionResource.find_by_sql(query)
  end

  def self.search_collection_column(limit_condition, solr, query, counter, fq_filters_inner)
    collection_limiter = limit_condition.clone
    collection_limiter.sub! 'collection_id_is', 'id_is'
    collection_title_condition = CollectionResource.search_perp(query, 'collection_title_text')
    collections_raw = solr.get 'select', params: { q: '*:*', fq: ['document_type_ss:collection', 'status_ss:active', collection_limiter, collection_title_condition], fl: %w[id_is title_ss] }
    collections_raw['response']['docs'].each do |single_collection|
      fq_filters_inner = fq_filters_inner + (counter != 0 ? ' OR ' : ' ') + "collection_id_is: #{single_collection['id_is']}"
      counter += 1
    end
    [fq_filters_inner, counter]
  end
end
