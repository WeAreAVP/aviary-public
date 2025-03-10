require 'open-uri'
# ResourceFile
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class CollectionResourceFile < ApplicationRecord
  include ActionView::Helpers
  belongs_to :collection_resource
  has_many :file_indexes, dependent: :destroy
  has_many :file_transcripts, dependent: :destroy
  has_many :playlist_items, dependent: :destroy
  attribute :access, :integer
  enum access: %i[no yes]
  attribute :transcode_status, :integer
  enum transcode_status: { pending: 0, in_progress: 1, completed: 2, not_needed: 3 }
  has_attached_file :resource_file, { default_url: '', validate_media_type: false }.merge(USE_STORAGE_PARAMS_FOR_ATTACHMENTS ? STORAGE_FOR_ATTACHMENTS : {})
  has_attached_file :thumbnail, styles: { small: '450x230>', medium: '2000x411>', processors: %i[thumbnail compression] }, default_url: ''
  validates_with AttachmentSizeValidator, attributes: :resource_file, less_than: 25.gigabytes, message: 'Resource File cannot be more then 25GBs'
  validates_attachment_content_type :resource_file, content_type: ['application/octet-stream', 'audio/mpeg', 'audio/ogg', 'audio/x-wav', 'audio/mp3', 'audio/x-m4a', 'audio/mp4', 'video/ogg', 'video/x-flv', 'video/webm',
                                                                   'video/mp4', 'video/quicktime'], message: "We're sorry, but the file or link you provided is not valid or is not supported by Aviary."
  validate :generate_thumbnail
  scope :order_file, -> { order('sort_order ASC') }
  after_create :update_storage
  after_save :update_duration, :update_object_permissions, :reindex_collection_resource
  after_destroy :update_duration, :reindex_collection_resource
  before_save :default_values
  before_update :set_total_time_enabled
  after_find :check_downloadable

  searchable do
    integer :id, stored: true
    string :resource_file_file_name, stored: true
    string :access, stored: true
    string :resource_file_content_type, stored: true
    string :resource_file_file_size, stored: true
    long :resource_file_file_size, stored: true
    string :file_display_name, stored: true
    string :sort_order, stored: true
    integer :sort_order, stored: true
    string :is_cc_on, stored: true
    begin
      time :resource_file_updated_at, stored: true
      time :created_at, stored: true
      time :updated_at, stored: true
    rescue StandardError => ex
      puts ex.backtrace.join("\n")
    end

    string :document_type, stored: true do
      'collection_resource_file'
    end

    string :count_of_transcripts, stored: true do
      file_transcripts.count
    end

    string :count_of_indexes, stored: true do
      file_indexes.count
    end

    string :collection_resource_id, stored: true do
      collection_resource.id
    end

    integer :collection_id, stored: true do
      collection_resource.collection.id
    end

    integer :organization_id, multiple: false, stored: true do
      collection_resource.collection.organization_id
    end

    string :collection_resource_title, stored: true do
      collection_resource.title
    end

    string :thumbnail, stored: true do
      thumbnail.url
    end

    string :aviary_url_path, stored: true do
      resource_file.url
    end

    string :aviary_embed_code, stored: true do
      resource_file.url
    end
    string :target_domain, stored: true
    string :duration, stored: true
    long :duration, stored: true
    string :is_downloadable, stored: true
    text :embed_code, stored: true
    string :embed_code_type, stored: true do
      embed_type.present? ? embed_type : 0
    end
  end

  def self.fields_values
    { 'id_is' => 'ID',
      'resource_file_file_name_ss' => 'File Name',
      'access_ss' => 'Public',
      'resource_file_content_type_ss' => 'Media Type',
      'resource_file_file_size_ss' => 'File Size',
      'updated_at_ds' => 'Date Updated',
      'created_at_ds' => 'Date Added',
      'count_of_transcripts_ss' => 'Count of Transcripts',
      'count_of_indexes_ss' => 'Count of Indexes',
      'collection_resource_id_ss' => 'Linked Resource Id',
      'collection_resource_title_ss' => 'Linked Resource Title',
      'thumbnail_ss' => 'Thumbnail',
      'file_display_name_ss' => 'Display name',
      'aviary_url_path_ss' => 'Aviary URL',
      'aviary_purl_ss' => 'Aviary PURL',
      'media_embed_url_ss' => 'Aviary Media Embed URL',
      'player_embed_html_ss' => 'Aviary Player Embed HTML',
      'resource_detail_embed_html_ss' => 'Aviary Resource Detail Embed HTML',
      'target_domain_ss' => 'Target Domain',
      'duration_ss' => 'Duration',
      'collection_title_text' => 'Collection Title',
      'sort_order_ss' => 'Sequence #',
      'sort_order_is' => 'Sequence #',
      'is_downloadable_ss' => 'Downloadable?',
      'is_cc_on_ss' => 'Turn on CC?',
      'embed_code_texts' => 'Media Embed Code',
      'embed_code_type_ss' => 'Embed Code Type' }
  end

  def self.media_file_field_label(system_name, organization = current_organization)
    resource_fields = organization.organization_field.resource_fields
    return fields_values[system_name] unless resource_fields[field_name(system_name)].present?

    fields_values[system_name] + (add_asterisk?(resource_fields[field_name(system_name)]) ? ' *' : '')
  end

  def self.field_name(system_name)
    system_name.sub(/_(ds|ss|is|sms|lms|texts)$/, '') if system_name.present?
  end

  def self.add_asterisk?(field)
    field['is_default'].to_s.to_boolean?
  end

  def self.date_time_format(date_time)
    date_time.to_datetime.strftime('%m-%d-%Y %H:%M:%S')
  end

  def default_values
    self.access ||= 1
    self.is_downloadable ||= false
    self.file_display_name ||= resource_file_file_name
  end

  def reindex_collection_resource
    begin
      reload
    rescue StandardError => e
      puts e
    end

    collection_resource.reindex_collection_resource
  end

  def update_duration
    collection_resource.update_duration
  end

  def update_object_permissions
    Rails.logger.info 'Updating S3 Permission'
    return unless resource_file.present?
    begin
      if access.eql?('yes')
        Rails.logger.info 'Setting up S3 Obhect to public read'
        resource_file.s3_object.acl.put(acl: 'public-read')
      else
        Rails.logger.info 'Setting up S3 Object to private'
        resource_file.s3_object.acl.put(acl: 'private')
      end
    rescue StandardError => e
      Rails.logger.info 'Error Here S3'
      Rails.logger.info e.message
      Rails.logger.info e.backtrace.inspect
    end
  end

  def generate_thumbnail
    return if resource_file.queued_for_write.length.zero?
    require 'streamio-ffmpeg'
    tmpfile = resource_file.queued_for_write[:original]

    unless File.extname(tmpfile.original_filename).present?
      require 'rack/mime'
      extension = Rack::Mime::MIME_TYPES.invert[tmpfile.content_type]
      extension = '.mov' if extension == '.qt'
      extension = '.mp4' if ['.mp4a', '.mp4v'].include?(extension)
      resource_file.instance_write(:file_name, "#{tmpfile.original_filename}#{extension}")
    end

    begin
      movie = FFMPEG::Movie.new(tmpfile.path)
      return unless movie.video_stream.present? || movie.audio_stream.present?
      self.duration = movie.duration
      self.transcode_status = :not_needed
      return unless movie.video_stream.present?
      return if thumbnail.to_s.length.nonzero?
      file_path = "#{tmpfile.original_filename}_#{Time.now.to_i}.jpg"
      seek_time = movie.duration > 31 ? 30 : 1 # take the frame at 30 second if video duration is more otherwise 1 frame.
      screenshot = movie.screenshot(file_path, { seek_time: seek_time, resolution: "#{movie.width}x#{movie.height}" }, preserve_aspect_ratio: :width)
      self.thumbnail = open(screenshot.path)
      self.transcode_status = :pending
      File.delete(file_path)
    rescue StandardError => ex
      puts ex.backtrace.join('')
    end
  end

  def generate_secure_url
    expiry = duration.to_f * 2
    resource_file.expiring_url(expiry.ceil)
  end

  # PlayerType
  class PlayerType
    YOUTUBE = 1
    DAILY_MOTION = 2
    VIMEO = 3
    AVALON = 4
    SOUNDCLOUD = 8
    OTHER = 0
    NAMES = { OTHER => 'Local Media Server', AVALON => 'Avalon', VIMEO => 'Vimeo', YOUTUBE => 'Youtube' }.freeze
    NAME_HUMANIZE = { OTHER => 'Local Media server', AVALON => 'Avalon', SOUNDCLOUD => 'Soundcloud', VIMEO => 'Vimeo', YOUTUBE => 'Youtube' }.freeze

    def self.for_select
      NAMES.invert.to_a
    end

    def self.name(embed_type)
      NAMES[embed_type]
    end
  end

  def self.embed_type_name(embed_type)
    PlayerType.name(embed_type)
  end

  def thumbnail_image
    if thumbnail.present?
      thumbnail.url(:small)
    elsif embed_type.to_s.include?('video') || resource_file_content_type.to_s.include?('video')
      "https://#{ENV.fetch('S3_HOST_CDN', nil)}/public/images/video-default.png"
    else
      "https://#{ENV.fetch('S3_HOST_CDN', nil)}/public/images/audio-default.png"
    end
  end

  def media_direct_url(expiry = 2)
    if embed_code.present? && embed_type
      embed_code
    else
      expiry = duration.to_f * expiry
      resource_file.expiring_url(expiry.ceil)
    end
  end

  def media_content_type
    if embed_code.present? && embed_type
      embed_content_type
    else
      content_type = resource_file_content_type
      content_type = 'video/mp4' if resource_file_content_type == 'video/quicktime'
      content_type
    end
  end

  def set_bucket
    collection_resource.collection.organization.bucket_name
  rescue StandardError => ex
    puts ex.backtrace.join("\n")
  end

  def check_downloadable
    self.is_downloadable = false if !try('is_downloadable').nil? && self.is_downloadable && !total_time_enabled.nil? && total_time_enabled.past?
  end

  def set_total_time_enabled
    self.total_time_enabled = if download_enabled_for_changed? || downloadable_duration_changed?
                                unless download_enabled_for.empty? && downloadable_duration.empty?
                                  if download_enabled_for.eql?('hour')
                                    Time.now.advance(hours: downloadable_duration.to_i)
                                  elsif download_enabled_for.eql?('day')
                                    Time.now.advance(days: downloadable_duration.to_i)
                                  else
                                    Time.strptime(downloadable_duration.to_s, '%m/%d/%Y')
                                  end
                                end
                              end
  end

  def update_storage
    # TranscodingJob.set(wait: 1.minute).perform_later(self) TODO: Need to address it
    return if resource_file_file_size.nil?
    file_size = resource_file_file_size / (1024 * 1024)
    organization = collection_resource.collection.organization
    storage = organization.storage_used.to_f + file_size
    organization.update_attribute('storage_used', storage)
  end

  def self.resource_file_size(organization_id)
    size = CollectionResourceFile.select('SUM(collection_resource_files.resource_file_file_size) AS total_size')
                                 .joins('INNER JOIN collection_resources ON collection_resources.id = collection_resource_files.collection_resource_id')
                                 .joins('INNER JOIN collections ON collections.id = collection_resources.collection_id')
                                 .joins('INNER JOIN organizations ON collections.organization_id = organizations.id')
                                 .where('organizations.id = ? ', organization_id).first
    size.present? ? size.total_size.to_f / (1024 * 1024) : 0
  end

  def self.fetch_file_list(page, per_page, sort_column, sort_direction, params, limit_condition, export_and_current_organization = { export: false, current_organization: false })
    q = params[:search][:value] if params.present? && params.key?(:search) && params[:search].key?(:value)
    solr_url = CollectionResource.solr_path
    solr = CollectionResource.solr_connect
    select_url = "#{solr_url}/select"
    solr_q_condition = '*:*'
    complex_phrase_def_type = false
    fq_filters = ' document_type_ss:collection_resource_file  '
    sort_column = sort_column.sub(/_(ss|sms)$/, '_scis')
    if q.present?
      counter = 0
      fq_filters_inner = ''
      JSON.parse(export_and_current_organization[:current_organization][:resource_file_search_column]).each do |_, value|
        if value['status'] == 'true'
          value['value'] = value['value'].sub(/_(ss|sms)$/, '_scis')
          unless value['value'].to_s == 'id_is' && q.to_i <= 0
            fq_filters_inner = fq_filters_inner + (counter != 0 ? ' OR ' : ' ') + " #{CollectionResource.search_perp(q, value['value'].to_s)} "
            counter += 1
            if value['value'].to_s == 'id_is'
              fq_filters_inner = fq_filters_inner + (counter != 0 ? ' OR ' : ' ') + " #{CollectionResource.search_perp(q, 'id')} "
            end
            if value['value'].to_s == 'collection_title_text'
              fq_filters_inner, counter = CollectionResource.search_collection_column(limit_condition, solr, q, counter, fq_filters_inner)
            end
          end
        end
      end
      fq_filters += " AND (#{fq_filters_inner}) " unless fq_filters_inner.blank?
    end
    filters = []
    filters << fq_filters

    filters << limit_condition if limit_condition.present?
    query_params = { q: solr_q_condition, fq: filters.flatten }
    query_params[:fq] << if export_and_current_organization[:current_organization].present?
                           "organization_id_is:#{export_and_current_organization[:current_organization].id}"
                         else
                           'id_is:0'
                         end
    query_params[:defType] = 'complexphrase' if complex_phrase_def_type
    query_params[:wt] = 'json'
    total_response = Curl.post(select_url, URI.encode_www_form(query_params))
    begin
      total_response = JSON.parse(total_response.body_str)

      if total_response['error'].present?
        Rails.logger.error total_response['error']['msg']
        raise 'There is an error in the query'
      end
    rescue StandardError
      total_response = { 'response' => { 'numFound' => 0 } }
    end
    query_params[:sort] = if sort_column.to_s == 'collection_title_text'
                            CollectionResourceFile.collection_sorter(limit_condition, sort_direction, solr)
                          elsif sort_column.to_s == 'resource_file_file_size_ss'
                            "resource_file_file_size_ls #{sort_direction}"
                          elsif sort_column.to_s == 'duration_ss'
                            "duration_ls #{sort_direction}"
                          elsif sort_column.present? && sort_direction.present?
                            "#{sort_column} #{sort_direction}"
                          end
    if export_and_current_organization[:export]
      query_params[:start] = 0
      query_params[:rows] = 100_000_000
    else
      query_params[:start] = (page - 1) * per_page
      query_params[:rows] = per_page
    end
    response = Curl.post(select_url, URI.encode_www_form(query_params))
    begin
      response = JSON.parse(response.body_str)

      if response['error'].present?
        Rails.logger.error response['error']['msg']
        raise 'There is an error in the query'
      end
    rescue StandardError
      response = { 'response' => { 'docs' => {} } }
    end
    count = total_response['response']['numFound'].to_i
    [response['response']['docs'], count, nil, export_and_current_organization[:current_organization]]
  end

  def self.to_csv(current_organization, base_url, limit_resource_ids, params)
    data = CollectionResourceFile.fetch_file_list(0, 0, 'id_is', 'desc', params, limit_resource_ids, export: true, current_organization: current_organization)
    header = JSON.parse(current_organization.resource_file_display_column)['columns_status'].map { |_, a| CollectionResourceFile.fields_values[a['value']] if a['status'] == 'true' }.compact
    columns = JSON.parse(current_organization.resource_file_display_column)['columns_status'].map { |_, a| a['value'] if a['status'] == 'true' }.compact
    CSV.generate(headers: true) do |csv|
      csv << header
      data.first.each do |resource|
        collection_resource = CollectionResource.find(resource['collection_resource_id_ss'])
        col_data = []
        columns.each do |value|
          next if value.blank?
          col_data << if value == 'resource_file_file_size_ss'
                        resource[value].present? ? ApplicationController.helpers.number_to_human_size(resource[value]) : ''
                      elsif %w[created_at_ds updated_at_ds].include?(value)
                        resource[value].present? ? resource[value].to_date.strftime('%m-%d-%Y') : ''
                      elsif value == 'access_ss'
                        resource[value].titleize
                      elsif value == 'resource_file_content_type_ss'
                        resource[value].present? ? resource[value] : ''
                      elsif value == 'duration_ss'
                        resource[value].present? ? ApplicationController.helpers.time_to_duration(resource[value]) : '00:00:00'
                      elsif value == 'thumbnail_ss'
                        '<img src=' + resource[value] + ' width= "50">'
                      elsif value == 'aviary_url_path_ss'
                        base_url + "/collections/#{collection_resource.collection.id}/collection_resources/#{resource['collection_resource_id_ss']}/file/#{resource['id_is']}"
                      elsif value == 'aviary_embed_code_ss'
                        base_url + "/collections/#{collection_resource.collection.id}/collection_resources/#{resource['collection_resource_id_ss']}/file/#{resource['id_is']}?embed=true"
                      elsif value == 'aviary_purl_ss'
                        base_url + "/r/#{collection_resource.noid}"
                      elsif value == 'media_embed_url_ss'
                        "#{base_url}/embed/media/#{resource['id_is']}"
                      elsif value == 'player_embed_html_ss'
                        "<iframe src='#{base_url}/embed/media/#{resource['id_is']}' ></iframe>"
                      elsif value == 'resource_detail_embed_html_ss'
                        link = "#{base_url}/collections/#{collection_resource.collection.id}/collection_resources/#{resource['collection_resource_id_ss']}/file/#{resource['id_is']}?embed=true"
                        "<iframe src='#{link}'></iframe>"
                      else
                        resource[value].present? ? resource[value] : ''
                      end
        end
        csv << col_data
      end
    end
  end

  def self.collection_sorter(limit_condition, sort_direction, solr)
    collections_raw = solr.post "select?#{URI.encode_www_form({ q: '*:*', fq: ['document_type_ss:collection', 'status_ss:active', limit_condition], wt: 'json', fl: %w[id_is], sort: 'title_ss desc' })}"
    response = collections_raw['response'].present? && collections_raw['response']['docs'].present? ? collections_raw['response']['docs'] : nil
    if response.present? && !response.size.zero?
      sort = ''
      total = response.size
      response.each do |testing|
        sort += "if(eq(collection_id_is,#{testing['id_is']}), #{total} ,"
        total -= 1
      end
      sort += '0'
      (1..response.size).each do |_i|
        sort += ')'
      end
      sort.present? ? "#{sort} #{sort_direction}" : "collection_id_is #{sort_direction}"
    else
      "collection_id_is #{sort_direction}"
    end
  end

  def reindex_collection_resource_file
    reload

    Sunspot.index self
    Sunspot.commit

    collection_resource.reindex_collection_resource
  end
end
