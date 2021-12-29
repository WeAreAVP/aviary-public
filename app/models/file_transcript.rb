# Model of FileTranscript
# models/file_transcript.rb
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class FileTranscript < ApplicationRecord
  include XMLFileHandler
  include ApplicationHelper
  belongs_to :collection_resource_file, optional: true
  belongs_to :interview, class_name: 'Interviews::Interview', optional: true
  has_one :annotation_set, dependent: :destroy
  has_many :file_transcript_points, dependent: :destroy
  belongs_to :user
  validates_presence_of :title, :language, message: 'is required.'
  validates_inclusion_of :is_public, in: [true, false], message: 'is required.'
  validate :validate_file
  has_attached_file :associated_file, validate_media_type: false, default_url: ''
  validates_attachment_content_type :associated_file, content_type: ['text/xml', 'application/xml', 'text/vtt', 'text/plain',
                                                                     'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                                                                     'application/msword', 'application/zip'],
                                                      message: 'Only XML, WebVTT, TXT, Doc and Docx formats allowed.'
  attr_accessor :remove_title
  scope :order_transcript, -> { order('sort_order ASC') }
  scope :public_transcript, -> { where(is_public: true).order_transcript }
  scope :cc, -> { where(is_caption: true) }
  after_save :update_solr
  after_destroy :update_solr

  def update_solr
    collection_resource_file.collection_resource.reindex_collection_resource if should_index?
  end

  def should_index?
    interview_id.blank?
  end

  def validate_file
    return if associated_file.present? && associated_file.queued_for_write[:original].nil?
    file_content_type = associated_file.queued_for_write[:original].content_type
    if !['text/plain', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/msword'].include?(file_content_type)
      doc = Nokogiri::XML(File.read(associated_file.queued_for_write[:original].path))
      error_messages = xml_validation(doc, 'transcript')
      if error_messages.any?
        errors.add(:associated_file, 'Invalid File, please select a valid OHMS XML file.')
      end
      xml_hash = Hash.from_xml(doc.to_s)
      transcript = xml_hash['ROOT']['record']['transcript']
      if transcript.nil?
        errors.add(:associated_file, 'Transcript is empty.')
      end
    elsif file_content_type == 'text/vtt' || ['.vtt', '.webvtt'].include?(File.extname(associated_file.queued_for_write[:original].original_filename).downcase)
      require 'webvtt'
      begin
        WebVTT.read(associated_file.queued_for_write[:original].path)
      rescue StandardError => ex
        errors.add(:associated_file, ex.message)
      end
    end
  end

  def self.fetch_transcript_list(page, per_page, sort_column, sort_direction, params, limit_condition, export_and_current_organization = { export: false, current_organization: false })
    q = params[:search][:value] if params.present? && params.key?(:search) && params[:search].key?(:value)
    solr = FileTranscript.solr_connect
    solr_url = FileTranscript.solr_path
    select_url = "#{solr_url}/select"
    solr_q_condition = '*:*'
    complex_phrase_def_type = false
    fq_filters = ' document_type_ss:file_transcript  '
    if q.present?
      counter = 0
      fq_filters_inner = ''
      JSON.parse(export_and_current_organization[:current_organization][:transcript_search_column]).each do |_, value|
        if value['status'] == 'true' || value['status'].to_s.to_boolean?
          unless value['value'].to_s == 'id_is' && q.to_i <= 0
            fq_filters_inner = fq_filters_inner + (counter != 0 ? ' OR ' : ' ') + " #{CollectionResource.search_perp(q, value['value'].to_s)} "
            counter += 1
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
    total_response = Curl.post(select_url, query_params)
    begin
      total_response = JSON.parse(total_response.body_str)
    rescue StandardError
      total_response = { 'response' => { 'numFound' => 0 } }
    end
    query_params[:sort] = if sort_column.to_s == 'collection_title_text'
                            CollectionResourceFile.collection_sorter(limit_condition, sort_direction, solr)
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
    response = Curl.post(select_url, query_params)
    begin
      response = JSON.parse(response.body_str)
    rescue StandardError
      response = { 'response' => { 'docs' => {} } }
    end
    count = total_response['response']['numFound'].to_i
    [response['response']['docs'], count, {}, export_and_current_organization[:current_organization]]
  end

  def self.permission_group_columns
    { columns_status: { '0' => { value: 'id_is', status: 'true' },
                        '1' => { value: 'title_ss', status: 'true' },
                        '2' => { value: 'is_public_ss', status: 'true' },
                        '3' => { value: 'file_display_name_ss', status: 'true' },
                        '4' => { value: 'collection_resource_title_ss', status: 'true' } } }
  end

  def self.fields_values
    {
      'id_is' => 'ID',
      'title_ss' => 'Name',
      'is_public_ss' => 'Public',
      'language_ss' => 'Language',
      'description_ss' => 'Notes',
      'file_display_name_ss' => 'Media File',
      'collection_resource_title_ss' => 'Resource Title',
      'annotation_count_is' => 'Annotation Set Count',
      'updated_at_ds' => 'Date Updated',
      'created_at_ds' => 'Date Added'
    }
  end

  def self.solr_path
    ENV['SOLR_URL'].blank? ? "http://127.0.0.1:8983/solr/#{Rails.env}" : ENV['SOLR_URL']
  end

  def self.solr_connect
    RSolr.connect url: solr_path
  end

  searchable if: :should_index? do
    integer :id, stored: true
    integer :collection_resource_file_id, stored: true
    integer :user_id, stored: true
    string :title, stored: true
    string :language, stored: true do
      languages_array_simple[0][language]
    end
    string :description, stored: true
    time :updated_at, stored: true
    time :created_at, stored: true

    string :is_public, multiple: false, stored: true do
      is_public == true ? 'Yes' : 'No'
    end

    integer :organization_id, multiple: false, stored: true do
      collection_resource_file.collection_resource.collection.organization_id
    end
    integer :annotation_count, multiple: false, stored: true do
      annotation_set.present? ? 1 : 0
    end
    string :file_display_name, multiple: false, stored: true do
      collection_resource_file.file_display_name
    end
    string :collection_resource_title, stored: true do
      collection_resource_file.collection_resource.title
    end
    string :document_type, stored: true do
      'file_transcript'
    end
  end
end
