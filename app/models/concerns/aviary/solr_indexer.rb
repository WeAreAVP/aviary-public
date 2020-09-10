# models/concerns/resource_file_management.rb
# Module Aviary::SolrIndexer
# SolrIndex
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
    self.trans_points_solr = { speaker: [], text: [], writing_direction: [], title: [] }
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
  end

  def self.define_custom_field_system_name(system_name, type = nil, append_solr_type = false)
    field_name = 'custom_field_values_' + system_name
    if append_solr_type
      type_field = Aviary::SolrIndexer.field_type_finder(type)
      field_name = field_name.to_s + type_field
    end
    field_name
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

  def description_values_fetch
    self.description_values_solr = {}
    self.custom_description_solr = {}
    begin
      resource_values = all_fields
    rescue
      resource_values = []
    end
    return unless resource_values.present?
    resource_values['CollectionResource'].each do |res|
      next if !res['values'].empty? && res['values'][0]['value'] == '' && res['values'][0]['vocab_value'] == ''
      field_name = res['field'].system_name

      if res['field'].is_custom
        field_name = Aviary::SolrIndexer.define_custom_field_system_name(field_name)
      end

      unless description_values_solr.key?(field_name)
        description_values_solr[field_name] = [] unless res['field'].is_custom
        description_values_solr["#{field_name}_search"] = [] unless res['field'].is_custom
      end

      res['values'].each do |val|
        vocab = ''
        if val['vocab_value'].present? || val['value'].present?
          value = val['value'].to_s
          value = languages_array_simple[0][value] if res['field'].system_name == 'language' && languages_array_simple[0][value].present?
          value = ActionController::Base.helpers.strip_tags(value)
          value_with_vocab = value
          if res['field'].is_vocabulary
            vocab = val['vocab_value']
            value_with_vocab = vocab.to_s + ' :: ' + value.to_s
          end
          if field_name.include?('custom_field_values') || res['field'].is_custom
            custom_description_solr[field_name] ||= {}
            custom_description_solr[field_name]['value'] ||= []
            custom_description_solr[field_name]['type'] = res['field'].fetch_type
            custom_description_solr[field_name]['value'] << value_with_vocab
          elsif res['field'].system_name == 'coverage'
            description_values_solr["#{field_name}_search"] << value_with_vocab
          elsif res['field'].system_name == 'duration'
            value = ((value.present? && !value.empty? ? value : '00:00:00').split(':').map(&:to_i).inject(0) { |a, b| a * 60 + b }.to_f / 60).round(2)
            description_values_solr["#{field_name}_search"] << value
          else
            description_values_solr["#{field_name}_search"] << if res['field'].system_name == 'date'
                                                                 Aviary::SolrIndexer.date_handler(value)
                                                               else
                                                                 value_with_vocab
                                                               end
          end

          description_values_solr['all_vocabs'] = [] unless description_values_solr['all_vocabs'].present?
          description_values_solr['all_vocabs'] << vocab if vocab.present? && !description_values_solr['all_vocabs'].include?(vocab)
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
      case value.scan(/(?=#{'-'})/).count
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
