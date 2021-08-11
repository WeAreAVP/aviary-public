# models/concerns/resource_file_management.rb
# Module Aviary::SolrIndexer
# SolrIndex
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Aviary::SolrIndexer
  extend ActiveSupport::Concern
  include ApplicationHelper

  def reindex_collection_resource
    update_attributes_solr
    reload
    begin
      index_points_fetch
      transcript_points_fetch
      description_values_fetch
      Sunspot.index self
      Sunspot.commit
    rescue StandardError => ex
      puts ex.backtrace.join("\n")
    end
  end

  def index_points_fetch
    self.index_points_solr = {}
    return [] unless CollectionResourceFile.where(collection_resource_id: id).present?
    file_ids = CollectionResourceFile.where(collection_resource_id: id).map(&:id)
    ids = nil
    ids = FileIndex.where(collection_resource_file_id: file_ids).pluck(:id) if file_ids.present?
    return [] unless ids.present?
    self.index_points_solr = { title: [], synopsis: [], subjects: [], keywords: [], partial_script: [] }
    file_points = FileIndexPoint.where(file_index_id: ids)
    file_points.each do |single_index_point|
      index_points_solr[:title] << single_index_point.title
      index_points_solr[:synopsis] << single_index_point.synopsis
      index_points_solr[:subjects] << single_index_point.subjects
      index_points_solr[:keywords] << single_index_point.keywords
      index_points_solr[:partial_script] << single_index_point.partial_script
    end
  end

  def transcript_points_fetch
    self.trans_points_solr = {}
    return [] unless CollectionResourceFile.where(collection_resource_id: id).present?
    file_ids = CollectionResourceFile.where(collection_resource_id: id).map(&:id)
    self.trans_points_solr = { speaker: [], text: [], writing_direction: [], title: [], annotation_body_content: [] }
    ids = nil
    ids = FileTranscript.where(collection_resource_file_id: file_ids).pluck(:id) if file_ids.present?
    return [] unless ids.present?
    file_points = FileTranscriptPoint.where(file_transcript_id: ids)
    file_points.each do |single_transcript_point|
      trans_points_solr[:title] << single_transcript_point.title
      trans_points_solr[:text] << single_transcript_point.speaker.to_s + ' ' + single_transcript_point.text.to_s
      trans_points_solr[:speaker] << single_transcript_point.speaker.to_s
      trans_points_solr[:writing_direction] << single_transcript_point.writing_direction
    end
    Annotation.where(target_content_id: ids).map { |single_annotation| trans_points_solr[:annotation_body_content] << single_annotation.body_content } if ids.present?
  end

  def self.define_custom_field_system_name(system_name, type = nil, append_solr_type = false)
    field_name = 'custom_field_values_' + system_name
    if append_solr_type
      type_field = Aviary::SolrIndexer.field_type_finder(type)
      field_name = field_name.to_s + type_field
    end
    field_name
  end

  def description_values_fetch
    self.description_values_solr = {}
    self.custom_description_solr = {}
    @org_field_manager = Aviary::FieldManagement::OrganizationFieldManager.new
    @resource_fields_settings = @org_field_manager.organization_field_settings(collection.organization, nil, 'resource_fields')
    @collection_field_manager = Aviary::FieldManagement::CollectionFieldManager.new
    @resource_fields = @collection_field_manager.collection_resource_field_settings(collection, 'resource_fields')
    begin
      resource_values = all_fields
    rescue StandardError
      resource_values = []
    end
    resource_values = resource_description_value.resource_field_values if resource_description_value.present?
    return unless resource_values.present?
    resource_values.each_with_index do |(system_name, single_collection_field), _index|
      next if single_collection_field['values'].present? && !single_collection_field['values'].empty? && single_collection_field['values'][0]['value'] == '' && single_collection_field['values'][0]['vocab_value'] == ''
      field_name = system_name
      current_field_settings = @resource_fields_settings[system_name]
      begin
        field_name = Aviary::SolrIndexer.define_custom_field_system_name(field_name) unless current_field_settings['is_default'].to_s.to_boolean?
      rescue StandardError => ex
        Rails.logger.error ex
        next
      end
      unless description_values_solr.key?(field_name)
        description_values_solr[field_name] = [] if current_field_settings['is_default'].to_s.to_boolean?
        description_values_solr["#{field_name}_search"] = [] if current_field_settings['is_default'].to_s.to_boolean?
      end

      if single_collection_field.present? && single_collection_field['values'].present?
        single_collection_field['values'].each do |val|
          vocab = ''
          next if val.class.name != 'Hash'
          if val['vocab_value'].present? || val['value'].present?
            value = val['value'].to_s
            value = languages_array_simple[0][value] if system_name == 'language' && languages_array_simple[0][value].present?
            value = ActionController::Base.helpers.strip_tags(value)
            value_with_vocab = value

            if current_field_settings['is_vocabulary']
              vocab = val['vocab_value']
              value_with_vocab = vocab.to_s.present? ? vocab.to_s.strip + '::' + value.to_s.strip : value.to_s.strip
            end

            if field_name.include?('custom_field_values') || !current_field_settings['is_default'].to_s.to_boolean?
              custom_description_solr[field_name] ||= {}
              custom_description_solr[field_name]['value'] ||= []
              custom_description_solr[field_name]['type'] = single_collection_field['field_type']
              custom_description_solr[field_name]['value'] << value_with_vocab
              description_values_solr['custom_field_values_search'] ||= []
              description_values_solr['custom_field_values_search'] << value_with_vocab
            elsif system_name == 'coverage'
              description_values_solr["#{field_name}_search"] << value_with_vocab
            elsif system_name == 'duration'
              description_values_solr[field_name] << value
              value = ((value.present? && !value.empty? ? value : '00:00:00').split(':').map(&:to_i).inject(0) { |a, b| a * 60 + b }.to_f / 60).round(2)
              description_values_solr["#{field_name}_search"] << value
            else
              description_values_solr["#{field_name}_search"] << if system_name == 'date'
                                                                   Aviary::SolrIndexer.date_handler(value)
                                                                 else
                                                                   value_with_vocab
                                                                 end
            end
            begin
              description_values_solr[field_name] ||= []
              description_values_solr[field_name] << unless system_name == 'duration'
                                                       value_with_vocab
                                                     end
            rescue StandardError => e
              puts e
            end

            description_values_solr['all_vocabs'] = [] unless description_values_solr['all_vocabs'].present?
            description_values_solr['all_vocabs'] << vocab if vocab.present? && !description_values_solr['all_vocabs'].include?(vocab)
          end
        end
      end
    end
  end

  def self.field_type_finder(type)
    type_field = '_sms'
    case type
    when 'text', 'tokens', 'dropdown'
      type_field = '_sms'
    when 'date'
      type_field = '_lms'
    when 'editor'
      type_field = '_texts'
    end
    type_field
  end

  def self.remove_field_type_string(value)
    value = value.gsub('_sms', '')
    value = value.gsub('_lms', '')
    value.gsub('_texts', '')
  end

  def self.date_handler(value)
    begin
      value = value.blank? ? '' : value.strip
      case value.scan(/(?=-)/).count
      when 0
        value += '-01-01'
      when 1
        value += '-01'
      end
      begin
        Date.parse(value)
        value = value.to_time.utc.to_i
      rescue ArgumentError
        value = nil
      end
    rescue ArgumentError
      value = nil
    end
    value
  end
end
