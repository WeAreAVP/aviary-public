# SearchHelper
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module SearchHelper
  def tombstone_display(tombstone, random, document)
    label_values = []
    value = ''
    value_with_out_tags = ''
    value_with_label = ''
    # |::| Used for separating the each value
    tombstone_for_document = tombstone
    tombstone = tombstone.to_s.gsub('dms', 'sms').to_sym if tombstone == :description_date_dms
    tombstone = tombstone.to_s.gsub('_sms', '_search_texts') if tombstone == :description_type_sms
    if document[tombstone].present?
      label_to_slow = solr_to_aviary_description[tombstone_for_document].titleize
      value_with_label += "<strong>#{label_to_slow}</strong>: "
      if document[tombstone].first.include? '::'
        document[tombstone].each do |single_vocb_val|
          raw_voc_val = single_vocb_val.split('::')
          value += "<span class='badge badge-secondary'>#{raw_voc_val.first} </span> #{raw_voc_val.second} (@)"
          temp_with_out_tags = strip_tags(raw_voc_val.second)
          value_with_out_tags += "<span class='badge badge-secondary'>#{raw_voc_val.first} </span> #{temp_with_out_tags} (@)"
        end
      else
        value += if document[tombstone].class == Array
                   document[tombstone].join(', ')
                 else
                   document[tombstone]
                 end
        value_with_out_tags += if document[tombstone].class == Array
                                 strip_tags(document[tombstone].join(', '))
                               else
                                 strip_tags(document[tombstone])
                               end
      end
      value_with_label += value_with_out_tags
      label_values << label_to_slow
      label_values << "<p class='search_tombstone_cust'> #{value_with_label.gsub('(@)', '')} </p> <span class='moreclick' style='display: none;' data-id='#{random}'> ...more </span> "
      label_values << "<p class=''> #{value.gsub('(@)', '<br/>')} </p> "
    end
    label_values
  end

  def add_facet_params_to_form(search_facets)
    hidden_facets_fields = ''
    if search_facets
      if search_facets.key?('all') && !search_facets['all'].blank?
        search_facets['all'].each do |facet_name, facet_values|
          facet_values.each do |single_value|
            hidden_facets_fields += "<input type='hidden' name='f[#{facet_name}][]' value='#{single_value}' />"
          end
        end
      end

      if search_facets.key?('range') && !search_facets['range'].blank?
        search_facets['range'].each do |facet_name, facet_values|
          facet_values.each do |index, single_value|
            hidden_facets_fields += "<input type='hidden' name='range[#{facet_name}][#{index}]' value='#{single_value}' />"
          end
        end
      end
    end
    hidden_facets_fields
  end

  def document_detail_url(document, document_organization)
    this_organization = if !document_organization.blank?
                          document_organization
                        else
                          Organization.exists?(document['organization_id_is']) ? Organization.find(document['organization_id_is']) : ''
                        end
    begin
      resource_url = collection_collection_resource_details_url(collection_id: document['collection_id_is'], collection_resource_id: document['id_is'], host: Utilities::AviaryDomainHandler.subdomain_handler(this_organization))
      keywords = AdvanceSearchHelper.advance_search_query_only(session[:searched_keywords], true, session['solr_params'], stopwords)
      if keywords.present?
        resource_url = append_param_to_url(keywords.map { |_key, value| value }, resource_url)
      end
      resource_url
    rescue StandardError => e
      e.message
    end
  end

  def solr_tombstone_values(tombstone_fields)
    keys = []
    unless tombstone_fields['tombstone_fields_sms'].empty?
      tombstone_fields['tombstone_fields_sms'].each do |single_tombstone|
        if avairy_to_solr_description[single_tombstone].present? && avairy_to_solr_description[single_tombstone].class == Symbol
          keys << avairy_to_solr_description[single_tombstone]
        end
      end
    end
    keys
  end

  def render_collection_facet_value(id)
    title = ''
    if id.present?
      collection_info = Collection.search do
        with :class, Collection
        with(:id, id)
      end
      title = if !collection_info.results.empty?
                collection_info.results.first.title
              else
                Collection.exists?(id: id) ? Collection.find(id).title : id
              end
    end
    title
  end

  def render_organization_facet_value(id)
    title = ''
    if id.present?
      organization_info = Organization.search do
        with :class, Organization
        with(:id, id)
      end
      title = if !organization_info.results.empty?
                organization_info.results.first.name
              else
                Organization.exists?(id: id) ? Organization.find(id).name : id
              end
    end
    title
  end

  def avairy_to_solr_description(single = nil)
    mapper = {
      'title' => :description_title_sms, 'publisher' => :description_publisher_sms,
      'rights_statement' => :description_rights_statement_search_texts, 'source' => :description_source_sms, 'agent' => :description_agent_sms, 'date' => :description_date_dms,
      'coverage' => :description_coverage_sms, 'language' => :description_language_sms, 'description' => :description_description_search_texts, 'format' => :description_format_sms,
      'identifier' => :description_identifier_sms, 'relation' => :description_relation_sms, 'subject' => :description_subject_sms, 'keyword' => :description_keyword_sms, 'type' => :description_type_sms,
      'preferred_citation' => :description_preferred_citation_ss, 'source_metadata_uri' => :description_source_metadata_uri_ss, 'duration' => :description_duration_ss
    }
    !single.nil? ? mapper[single] : mapper
  end

  def solr_to_aviary_description(single = nil)
    mapper_solr = {
      description_title_sms: 'title', description_publisher_sms: 'publisher', description_rights_statement_search_texts: 'rights_statement', description_source_sms: 'source', description_agent_sms: 'agent',
      description_date_dms: 'date', description_coverage_sms: 'coverage', description_language_sms: 'language', description_description_search_texts: 'description', description_format_sms: 'format',
      description_identifier_sms: 'identifier', description_relation_sms: 'relation', description_subject_sms: 'subject', description_keyword_sms: 'keyword', description_type_sms: 'type',
      description_duration_ss: 'duration', description_source_metadata_uri_ss: 'source_metadata_uri', description_preferred_citation_ss: 'preferred_citation'
    }
    !single.nil? ? mapper_solr[single] : mapper_solr
  end

  def solr_collection(id)
    collection_info = Collection.search do
      with :class, Collection
      with(:id, id)
      facet :tombstone_fields
    end
    !collection_info.results.empty? ? [collection_info.facet_response['facet_fields'], collection_info.results.first] : nil
  end

  def solr_organization(id)
    organization_info = Organization.search do
      with :class, Organization
      with(:id, id)
    end
    !organization_info.results.empty? ? organization_info.results.first : nil
  end

  def collection_resource(id)
    !CollectionResource.where(id: id).empty? ? CollectionResource.find(id) : nil
  end
end
