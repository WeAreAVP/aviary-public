# frozen_string_literal: true

# Blacklight::Solr::InvalidParameter
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class Blacklight::Solr::InvalidParameter < ArgumentError
end

# class Blacklight::Solr::Request
# TODO: Please review this class thouroughly. The new request.rb has some changes that we might need to bring over here as well. (Refer to the blacklight-7.22.2 request.rb)
class Blacklight::Solr::Request < ActiveSupport::HashWithIndifferentAccess
  SINGULAR_KEYS = %w(facet fl q qt rows start spellcheck spellcheck.q sort per_page wt hl group defType).freeze
  ARRAY_KEYS = %w(facet.field facet.query facet.pivot fq hl.fl).freeze

  def initialize(constructor = {})
    if constructor.is_a?(Hash)
      super()
      update(constructor)
    else
      super(constructor)
    end
    ARRAY_KEYS.each do |key|
      self[key] ||= []
    end
  end

  # TODO: A new method from the request.rb class. Please review this method thouroughly to make sure it dosen't change the desired behaviour in any way
  def append_query(query)
    if self['q'] || dig(:json, :query, :bool)
      self[:json] ||= { query: { bool: { must: [] } } }
      self[:json][:query] ||= { bool: { must: [] } }
      self[:json][:query][:bool][:must] << query

      if self['q']
        self[:json][:query][:bool][:must] << self['q']
        delete 'q'
      end
    else
      self['q'] = query
    end
  end

  # TODO: A new method from the request.rb class. Please review this method thouroughly to make sure it dosen't change the desired behaviour in any way
  def append_boolean_query(bool_operator, query)
    return if query.blank?

    self[:json] ||= { query: { bool: { bool_operator => [] } } }
    self[:json][:query] ||= { bool: { bool_operator => [] } }
    self[:json][:query][:bool][bool_operator] ||= []

    if self['q']
      self[:json][:query][:bool][:must] ||= []
      self[:json][:query][:bool][:must] << self['q']
      delete 'q'
    end

    self[:json][:query][:bool][bool_operator] << query
  end

  def append_filter_query(query)
    if query.present? && (query.include?('collection_id_is') || query.include?('organization_id_is'))
      skippers = %w[description_date_search_lms description_language_search_facet_sms description_coverage_search_facet_sms has_transcript_ss has_index_ss
                    description_format_search_facet_sms description_subject_search_facet_sms description_type_search_facet_sms access_ss description_duration_ls]
      begin
        new_facet_selected = /.*}(.*)/.match(query)[1]
        facet_field_name = /^({.*})/.match(query)[1]
        if self['fq'].empty?
          append_filters_if_exists(new_facet_selected, facet_field_name)
        else
          flag_new = false
          self['fq'].each { |item|
            next if skippers.any? { |s| item.include?(s) } || item.to_s.end_with?('_lms')
            begin
              s = /.*}(.*\w)*:/.match(item)[1]
              flag_new = facet_field_name.include?(s) ? false : true
            rescue StandardError => e
              Rails.logger.error e
            end
          }
          if flag_new
            append_filters_if_exists(new_facet_selected, facet_field_name)
          else
            self['fq'].map! { |item|
              if skippers.any? { |s| item.include?(s) } || item.to_s.end_with?('_lms')
                return item
              end
              begin
                fac = /.*}(.*\w)*:/.match(item)[1]
                facet_field_name.include?(fac) ? /(.*\w)/.match(item)[1] << ' ' << new_facet_selected << ' )' : item
              rescue StandardError => e
                Rails.logger.error e
                item
              end
            }
          end
        end
      rescue StandardError => e
        Rails.logger.error e
        self['fq'] << query
      end
    elsif query.present?
      self['fq'] << query
    end
  end

  def append_filters_if_exists(new_facet_selected, facet_field_name)
    all_facets = %w[organization_id_is collection_id_is]
    flag_listed_facet = false
    all_facets.each do |single_facet|
      if facet_field_name.include? single_facet
        self['fq'] << "{!tag=#{single_facet}}#{single_facet}:( " + new_facet_selected + ' )'
        flag_listed_facet = true
      end
    end
    self['fq'] << query unless flag_listed_facet
  end

  def append_facet_fields(values)
    self['facet.field'] += Array(values)
  end

  def append_facet_query(values)
    self['facet.query'] += Array(values)
  end

  def append_facet_pivot(query)
    self['facet.pivot'] << query
  end

  def append_highlight_field(query)
    self['hl.fl'] << query
  end

  def to_hash
    reject { |key, value| ARRAY_KEYS.include?(key) && value.blank? }
  end
end
