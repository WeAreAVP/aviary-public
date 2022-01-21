# Search Builder
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder
  include BlacklightAdvancedSearch::AdvancedSearchBuilder
  include ApplicationHelper
  include DocumentHelper
  include SearchHelper
  attr_accessor :session_solr, :current_params, :request_is_xhr
  attr_accessor :current_organization, :current_user, :user_ip
  self.default_processor_chain += %i[add_advanced_parse_q_to_solr add_advanced_search_to_solr]
  self.default_processor_chain += [:show_only_public_records]

  def self.facets_list
    %i[keywords indexes title_text resource_description transcript collection_title]
  end

  def self.search_field_labels
    { 'keywords' => 'Any Field', 'indexes' => 'Indexes', 'title_text' => 'Resource Name', 'resource_description' => 'Resource Description', 'transcript' => 'Transcript', 'collection_title' => 'Collection Title' }
  end

  def advance_query_helper(field, query_string)
    "_query_:\"{!dismax qf=#{field} pf=#{field}}#{query_string}\""
  end

  def search_type_handler(search_string, type_of_field_search)
    case type_of_field_search
    when 'simple'
      search_string.strip.to_s
    when 'startswith'
      "#{search_string.strip}*"
    when 'endswith'
      "*#{search_string.strip}"
    when 'wildcard'
      "*#{search_string.strip}*"
    else
      "*#{search_string.strip}*"
    end
  end

  def collection_title_manager(query_string, search_string)
    non_resource_title_manage('collection', 'collection_id_is', 'status_ss:active', query_string, search_string, current_organization, %w[id_is title_ss])
  end

  def organization_title_manager(query_string, search_string)
    non_resource_title_manage('organization', 'organization_id_is', 'status_bs:true', query_string, search_string, current_organization, %w[id_is name_ss])
  end

  def non_resource_title_manage(type, id_field, status_condition, query_string, search_string, current_organization, title_field)
    query_collection = ' ((_query_:"{!complexphrase inOrder=true}' + type + '_title_text:\"' + query_string.strip + '\"" OR _query_:"{!complexphrase inOrder=true}' + type + '_title_text:\"' + search_string + '\"")) '
    condition_limiter = ["document_type_ss:#{type}", status_condition]
    condition_limiter << "organization_id_is:#{current_organization.id}" unless current_organization.blank?
    solr = CollectionResource.solr_connect
    collections_raw = solr.get 'select', params: { q: query_collection, defType: 'lucene', fq: condition_limiter, fl: title_field }
    counter = 0
    fq_filters_inner = ''
    collections_raw['response']['docs'].each do |single_collection|
      fq_filters_inner = fq_filters_inner + (counter != 0 ? ' OR ' : ' ') + " #{id_field}:#{single_collection['id_is']} "
      counter += 1
    end
    fq_filters_inner
  end

  def handle_wild_search(term)
    return "*#{term}*" if !term.include?('*') && !term.include?('"')
    term
  end

  def values_auto_wildcard_search(search_keyword, search_string)
    exact_search = search_keyword
    exact_search = handle_wild_search(exact_search)
    exact_search = exact_search.gsub %r{[\/\\|"&]}, ''
    search_string = search_string.gsub %r{[\/\\|"&]}, ''
    [exact_search, search_string]
  end

  def single_search_term_handler(single_param, solr_parameters, query_string, type, field_name = nil)
    op_custom = ''
    op_custom_global = ''
    query_string_mutate = ''
    paranthesis = single_param[field_name][single_param[field_name].index(/[()]/)] unless single_param[field_name].index(/[()]/).nil?
    single_param[field_name] = single_param[field_name].gsub(/[()]/, '')
    type_of_field_search = single_param['type_of_search'] if single_param.keys.include?('type_of_search')
    if single_param.keys.include?('title_text')
      op_custom_global = (single_param['op'] == 'NOT' ? 'AND NOT' : single_param['op']) if single_param.key?('op')
      search_string = if type == 'simple'
                        single_param['title_text'].delete('*')
                      else
                        search_type_handler(single_param['title_text'], type_of_field_search)
                      end
      exact_search, search_string = values_auto_wildcard_search(single_param['title_text'], search_string)
      single_param['title_text'] = single_param['title_text'].gsub %r{[\/\\|"&]}, ''
      query_string_mutate = if single_param['op'] == 'NOT'
                              ' ((_query_:"{!complexphrase inOrder=true}title_text:\"' + exact_search.strip + '\"") OR (_query_:"{!complexphrase inOrder=true}title_text:\"' + search_string + '\"")) '
                              +search_string + '\"")) '
                            else
                              ' ((_query_:"{!complexphrase inOrder=true}title_text:\"' + exact_search.strip +
                                '\"" OR _query_:"{!complexphrase inOrder=true}title_text:\"' + search_string + '\"")) '
                            end
    elsif single_param.keys.include?('resource_description')
      op_custom_global = (single_param['op'] == 'NOT' ? 'AND NOT' : single_param['op']) if single_param.key?('op')
      query_string_mutate = '(' unless op_custom_global == 'AND NOT'
      first = true
      [description_search_fields].reduce([], :concat).each do |single_field|
        op_custom = single_param['op'] == 'NOT' ? ' AND NOT ' : ' OR '
        op_custom = ' ' if first
        first = false
        search_string = if type == 'simple'
                          single_param['resource_description'].delete('*')
                        else
                          search_type_handler(single_param['resource_description'], type_of_field_search)
                        end

        exact_search, search_string = values_auto_wildcard_search(single_param['resource_description'], search_string)
        single_param['resource_description'] = single_param['resource_description'].gsub %r{[\/\\|"&]}, ''
        query_string_mutate_simple = if single_param['op'] == 'NOT'
                                       ' ((_query_:"{!complexphrase inOrder=true}' + single_field.to_s + ':\"' +
                                         exact_search.strip + '\"") OR (_query_:"{!complexphrase inOrder=true}' + single_field.to_s + ':\"' + search_string + '\"")) '
                                     else
                                       ' ((_query_:"{!complexphrase inOrder=true}' + single_field.to_s + ':\"' +
                                         exact_search.strip + '\"" OR _query_:"{!complexphrase inOrder=true}' + single_field.to_s + ':\"' + search_string + '\"")) '
                                     end
        query_string_mutate += op_custom + query_string_mutate_simple
      end
      query_string_mutate += ')' unless op_custom_global == 'AND NOT'
    elsif single_param.keys.include?('collection_title')
      op_custom_global = (single_param['op'] == 'NOT' ? 'AND NOT' : single_param['op']) if single_param.key?('op')
      type_of_field_search = single_param['type_of_search'] if single_param.keys.include?('type_of_search')
      search_string = if type == 'simple'
                        single_param['collection_title'].delete('*')
                      else
                        search_type_handler(single_param['collection_title'], type_of_field_search)
                      end
      fq_filters_inner = collection_title_manager(single_param['collection_title'], search_string)
      solr_parameters[:fq] << if fq_filters_inner.blank?
                                'collection_id_is:0'
                              else
                                fq_filters_inner
                              end

    elsif single_param.keys.include?('keywords')
      op_custom_global = (single_param['op'] == 'NOT' ? 'AND NOT' : single_param['op']) if single_param.key?('op')
      type_of_field_search = single_param['type_of_search'] if single_param.keys.include?('type_of_search')
      search_string = if type == 'simple'
                        single_param['keywords'].delete('*')
                      else
                        search_type_handler(single_param['keywords'], type_of_field_search)
                      end
      exact_search, search_string = values_auto_wildcard_search(single_param['keywords'], search_string)
      single_param['keywords'] = single_param['keywords'].gsub %r{[\/\\|"&]}, ''
      query_string_mutate = if single_param['op'] == 'NOT'
                              ' (_query_:"{!complexphrase inOrder=true}keywords:\"' +
                                exact_search.strip + '\"") OR (_query_:"{!complexphrase inOrder=true}keywords:\"' + search_string + '\"") '
                            else
                              query_string_mutate = ' ((_query_:"{!complexphrase inOrder=true}keywords:\"' +
                                                    exact_search.strip + '\"" OR _query_:"{!complexphrase inOrder=true}keywords:\"' + search_string + '\"")) '
                              fq_filters_inner = collection_title_manager(single_param['keywords'], search_string)
                              fq_filters_inner_organiztion = organization_title_manager(single_param['keywords'], search_string)
                              query_string_mutate += " OR (#{fq_filters_inner}) " unless fq_filters_inner.blank?
                              query_string_mutate += " OR (#{fq_filters_inner_organiztion}) " unless fq_filters_inner_organiztion.blank?
                              " ( #{query_string_mutate} ) "
                            end
    elsif single_param.keys.include?('indexes')
      op_custom_global = (single_param['op'] == 'NOT' ? 'AND NOT' : single_param['op']) if single_param.key?('op')
      query_string_mutate = '(' unless op_custom_global == 'AND NOT'
      first = true
      index_search_fields.each do |single_field|
        response_manager = manage_index_transcript('indexes', single_param, first, type_of_field_search, single_field)
        query_string_mutate += response_manager.first
        first = response_manager.second
      end
      query_string_mutate += ')' unless op_custom_global == 'AND NOT'
    elsif single_param.keys.include?('transcript')
      op_custom_global = (single_param['op'] == 'NOT' ? 'AND NOT' : single_param['op']) if single_param.key?('op')
      query_string_mutate = '(' unless op_custom_global == 'AND NOT'
      first = true
      transcript_search_fields.each do |single_field|
        response_manager = manage_index_transcript('transcript', single_param, first, type_of_field_search, single_field)
        query_string_mutate += response_manager.first
        first = response_manager.second
      end
      query_string_mutate += ')' unless op_custom_global == 'AND NOT'
    end
    if paranthesis.present?
      query_string_mutate = paranthesis == '(' ? "(#{query_string_mutate}" : "#{query_string_mutate})"
    end
    query_string += " #{op_custom_global} " if op_custom_global
    query_string += query_string_mutate if query_string_mutate
    [solr_parameters, query_string]
  end

  # The only purpose of this method is to debug errors in the solr query string
  # The query string will be appended to the file with Time, Actual query entered and Solr query being sent
  # Call this function to save the solr query string to store it in the public/query_string/query_string.rb file
  def save_query_string_to_file(query_string)
    path = "#{Rails.root.join('public')}/query_string"
    FileUtils.mkdir_p(path) unless File.exist?(path)
    query_string = query_string.strip
    count = 0
    formatted_query = ""
    query_string = query_string.gsub(/(\(\s*)/, "(").gsub(/(\s*\))/, ")")
    query_string = "(((#{query_string})))"
    query_string.split("").each_with_index do |ch, i|
      if ch == '(' && ("#{query_string[i - 3]}#{query_string[i - 2]}" != 'OR')
        count += 1
        ch = "(\n"
        count.times { ch += "\t" }
      elsif ch == ')' && ("#{query_string[i+2]}#{query_string[i + 3]}" != 'OR')
        count -= 1
        ch = "\n"
        count.times { ch += "\t" }
        ch += ")"
      end
      if %w[AND NOT].include?("#{query_string[i - 5]}#{query_string[i - 4]}#{query_string[i - 3]}") && ch == "("
        tabs = "\n"
        (count - 1).times { tabs += "\t"} 
        ch = tabs + ch
      end
      formatted_query += ch
    end
    File.open(path + '/query_strings.rb', 'a') do |f|
      f.puts("'Time': '#{Time.now.floor}'\n".gsub!('+0500', ''))
      f.puts("'Search Query': '#{session_solr[session_solr.keys.first][:keyword_searched]}'\n")
      f.puts("'Solr Query String':\n" )
      f.puts(formatted_query)
      f.puts("\n\n")
    end
  end

  def manage_index_transcript(type, single_param, first, type_of_field_search, single_field)
    op_custom = single_param['op'] == 'NOT' ? ' AND NOT ' : ' OR '
    op_custom = ' ' if first
    first = false
    search_string = if type == 'simple'
                      single_param[].delete('*')
                    else
                      search_type_handler(single_param[type], type_of_field_search)
                    end

    exact_search, search_string = values_auto_wildcard_search(single_param[type], search_string)
    single_param[type] = single_param[type].gsub %r{[\/\\|"&]}, ''
    query_string_mutate_simple = if single_param['op'] == 'NOT'
                                   ' ((_query_:"{!complexphrase inOrder=true}' + single_field.to_s + ':\"' +
                                     exact_search.strip + '\"") OR (_query_:"{!complexphrase inOrder=true}' + single_field.to_s + ':\"' + search_string + '\"")) '
                                 else
                                   ' ((_query_:"{!complexphrase inOrder=true}' + single_field.to_s + ':\"' +
                                     exact_search.strip + '\"" OR _query_:"{!complexphrase inOrder=true}' + single_field.to_s + ':\"' + search_string + '\"")) '
                                 end
    [op_custom + query_string_mutate_simple, first]
  end

  def self.remove_illegal_characters(query_str, type)
    query_str = if type == 'advance'
                  query_str.gsub %r{[\/\\()|'*:^~{}&]}, ''
                else
                  query_str.gsub %r{[\/\\|':^~{}&]}, ''
                end
    query_str = query_str.gsub(/]/, '')
    query_str.gsub(/[{}]/, '')
  end

  def advance_search_manage(solr_parameters, session_solr)
    query_string = ''
    session_solr.each do |key, single_param|
      unless key.blank?
        if single_param.keys.include?('title_text')
          single_param['title_text'] = SearchBuilder.remove_illegal_characters(single_param['title_text'], 'advance')
        elsif single_param.keys.include?('resource_description')
          single_param['resource_description'] = SearchBuilder.remove_illegal_characters(single_param['resource_description'], 'advance')
        elsif single_param.keys.include?('collection_title')
          single_param['collection_title'] = SearchBuilder.remove_illegal_characters(single_param['collection_title'], 'advance')
        elsif single_param.keys.include?('keywords')
          single_param['keywords'] = SearchBuilder.remove_illegal_characters(single_param['keywords'], 'advance')
        elsif single_param.keys.include?('indexes')
          single_param['indexes'] = SearchBuilder.remove_illegal_characters(single_param['indexes'], 'advance')
        elsif single_param.keys.include?('transcript')
          single_param['transcript'] = SearchBuilder.remove_illegal_characters(single_param['transcript'], 'advance')
        end
        solr_parameters, query_string = single_search_term_handler(single_param, solr_parameters, query_string, 'advance')
      end
    end
    query_string
  end

  def add_advanced_search_to_solr(solr_parameters)
    # If we've got the hint that we're doing an 'advanced' search, then
    # map that to solr #q, over-riding whatever some other logic may have set, yeah.
    # the hint right now is :search_field request param is set to a magic
    # key. OR of :f_inclusive is set for advanced params, we need processing too.
    return unless is_advanced_search?
    # Set this as a controller instance variable, not sure if some views/helpers depend on it. Better to leave it as a local variable
    # if not, more investigation later.
    solr_parameters['q'] ||= ''
    if current_params['search_type'] == 'advance' && session_solr.present?
      query_string = advance_search_manage(solr_parameters, session_solr)
      solr_parameters['q'] += query_string
    elsif session_solr.present?
      query_string = ''
      term = session_solr[session_solr.keys.first]['keyword_searched'].dup
      term = SearchBuilder.remove_illegal_characters(term, 'simple')
      all_terms = term.gsub(/OR/, '|||').gsub(/AND/, '|||').gsub(/NOT/, '|||').split('|||').map { |keyword| keyword.strip }
      filed_name = if session_solr[session_solr.keys.first].keys.include?('title_text')
                     'title_text'
                   elsif session_solr[session_solr.keys.first].keys.include?('resource_description')
                     'resource_description'
                   elsif session_solr[session_solr.keys.first].keys.include?('collection_title')
                     'collection_title'
                   elsif session_solr[session_solr.keys.first].keys.include?('keywords')
                     'keywords'
                   elsif session_solr[session_solr.keys.first].keys.include?('indexes')
                     'indexes'
                   elsif session_solr[session_solr.keys.first].keys.include?('transcript')
                     'transcript'
                   end
      all_terms.each do |single_term|
        operator = ''
        term = term.strip
        if term.split(" #{single_term} ").first.present? && term.index(single_term) > 1
          search_term = " #{single_term} "
          position_of_or = term.split(search_term).first.rindex('OR').present? ? term.split(search_term).first.rindex('OR') : -1
          position_of_and = term.split(search_term).first.rindex('AND').present? ? term.split(search_term).first.rindex('AND') : -1
          position_of_not = term.split(search_term).first.rindex('NOT').present? ? term.split(search_term).first.rindex('NOT') : -1
          operator = 'OR' if position_of_or.present?
          operator = 'AND' if position_of_and.present? && position_of_and > position_of_or
          operator = 'NOT' if position_of_not.present? && position_of_not > position_of_and
        end
        single_param = { 'type_of_search' => 'wildcard', 'op' => operator }
        single_param[filed_name] = single_term
        solr_parameters, query_string = single_search_term_handler(single_param, solr_parameters, query_string, 'simple', filed_name) if single_term.present?
      end
      # Uncomment below line if you want to read the formulated solr query string. Refer to the method documentation 
      # save_query_string_to_file(query_string)
      solr_parameters['q'] += ' ( ' + query_string + ' ) ' if query_string.present?
    end
  end

  def self.description_search_fields
    %i[ description_title_search_texts description_publisher_search_texts description_rights_statement_search_texts description_source_search_texts
        description_agent_search_texts description_date_search_texts description_coverage_search_texts description_language_search_texts description_description_search_texts
        description_format_search_texts description_identifier_search_texts description_relation_search_texts description_subject_search_texts description_keyword_search_texts
        description_type_search_texts description_preferred_citation_search_texts description_duration_citation_search_texts description_source_metadata_uri_search_texts custom_field_values_texts]
  end

  def self.index_search_fields
    %i[index_point_title_texts index_point_synopsis_texts index_point_subjects_texts index_point_keywords_texts index_point_partial_script_texts]
  end

  def self.transcript_search_fields
    %i[transcript_point_text_texts transcript_point_speaker_texts]
  end

  # fq supports wild card search thats why using fq for dropdown filters to make it as a wild card
  def show_only_public_records(solr_parameters)
    solr_parameters[:fq] ||= []
    # Start Date Range setup
    solr_parameters[:fq].each_with_index do |fq_single, index|
      if fq_single.include? 'description_duration_ls_single'
        solr_parameters[:fq].delete_at(index)
      end
      if fq_single.include?('description_date_search_lms') || (fq_single.include?('custom_field_values') && fq_single.include?('_lms'))
        date_range_n_field = fq_single.split(':')
        field = date_range_n_field[0]
        date_range = date_range_n_field[1]
        start_date = date_range[/\[(.*?)\ TO/]
        start_date['['] = ''
        start_date[' TO'] = ''
        start_date = start_date.split(' - ')
        end_date = start_date.second
        start_date = start_date.first
        start_date = start_date.to_time.to_i.to_s
        end_date = end_date.to_time.to_i.to_s
        solr_parameters[:fq] << "#{field}: [#{start_date} TO #{end_date}]"
        solr_parameters[:fq].delete_at(index)
        break
      end
    end

    # End Date Range setup
    resultant_fields_manager(solr_parameters) unless request_is_xhr
    solr_parameters = SearchBuilder.default_fqs(current_organization, user_ip, current_user, solr_parameters)
    solr_parameters[:fq] << "organization_id_is:(#{current_params[:f][:organization_id_is].join(' OR ')})" if current_params[:f].present? && current_params[:f][:organization_id_is].present?
    solr_parameters[:fq] << "collection_id_is:(#{current_params[:f][:collection_id_is].join(' OR ')})" if current_params[:f].present? && current_params[:f][:collection_id_is].present?
    solr_parameters['q'] ||= '*:*'
    return solr_parameters unless request_is_xhr
    solr_parameters['facet.field'] = []
    solr_parameters['rows'] = 100_000_000
    solr_parameters['fl'] = 'id_is'
    solr_parameters['facet'] = false
  end

  def self.default_fqs(current_organization, _user_ip, current_user, solr_parameters)
    resource_id_fq = ''
    collection_id_fq = ''
    private_where =  ''

    solr_parameters[:fq] << 'document_type_ss:collection_resource'
    solr_parameters[:fq] << '-{!join from=collection_collection_id_i to=resource_collection_id_i}status_ss:deleted'
    solr_parameters[:fq] << ' {!join from=organization_organization_id_i to=resource_organization_id_i}organization_status_b:true'
    solr_parameters[:fq] << " (access_ss:access_public OR access_ss:public_resource_restricted_content #{resource_id_fq}  #{collection_id_fq}) " if current_user.blank?
    user_organization_ids = nil
    user_organization_ids = current_user.organization_users.pluck(:organization_id).join(' OR ') if current_user.present?
    solr_parameters[:fq] << '-access_ss:access_private ' if user_organization_ids.blank? && private_where.blank?
    solr_parameters[:fq] << if user_organization_ids.blank?
                              "({!join from=collection_collection_id_i to=resource_collection_id_i}is_public_bs:true  #{resource_id_fq}  #{collection_id_fq}) #{private_where}"
                            else
                              filter = "({!join from=collection_collection_id_i to=resource_collection_id_i}is_public_bs:true  #{resource_id_fq}  #{collection_id_fq})"
                              " #{filter} OR ({!join from=collection_collection_id_i to=resource_collection_id_i}is_public_bs:false AND (organization_id_is:(#{user_organization_ids}) #{resource_id_fq}  #{collection_id_fq})) #{private_where}"
                            end
    all_resource_access = 'access_ss:access_public OR access_ss:public_resource_restricted_content OR access_ss:access_restricted'
    solr_parameters[:fq] << "#{all_resource_access} OR (access_ss:access_private AND (organization_id_is:(#{user_organization_ids}) #{resource_id_fq}  #{collection_id_fq}))" unless user_organization_ids.blank?
    solr_parameters[:fq] << "organization_id_is:#{current_organization.id}" unless current_organization.blank?
    solr_parameters
  end

  def resultant_fields_manager(solr_parameters)
    # Start Keyword occurrence in fields
    fl_maker = ' * '
    sum_score = []
    sum_score << 0
    all_keywords = SearchBuilder.keywords_array(session_solr)
    unless all_keywords.blank?
      [description_search_fields, index_search_fields, transcript_search_fields].reduce([], :concat).each do |values|
        all_keywords.each do |query_string|
          query_string = query_string.delete('"').strip
          query_string = SearchBuilder.remove_illegal_characters(query_string, 'advance')
          unless query_string.include?('*') || query_string.include?('(') || query_string.include?(')') || query_string.include?(',') || query_string.include?(',')
            if query_string.include? ' '
              query_string.split(' ').each do |single_query|
                unless stopwords.include?(single_query.to_s.downcase)
                  single_query = single_query.strip
                  fl_maker += ",#{values}_occurrence_#{single_query}:termfreq(#{values}, #{single_query})"
                  sum_score << " termfreq(#{values}, #{single_query}) "
                end
              end
            else
              unless stopwords.include?(query_string.to_s.downcase)
                query_string = query_string.strip
                fl_maker += ",#{values}_occurrence_#{query_string}:termfreq(#{values}, #{query_string})"
                sum_score << " termfreq(#{values}, #{query_string}) "
              end
            end
          end
        end
      end
    end

    solr_parameters[:fl] = fl_maker
    if solr_parameters[:sort].include?('score')
      solr_parameters[:sort] = " sum(#{sum_score.join(' , ')}) desc"
    end
    solr_parameters
  end

  def self.keywords_array(session_solr_all)
    all_keywords = []
    session_solr_all.each do |_, single_holder|
      query_string = ''
      SearchBuilder.facets_list.each do |single_facet|
        if single_holder.key?(single_facet.to_s) && !single_holder[single_facet.to_s].blank?
          query_string = if single_holder[single_facet.to_s].strip.index('AND') || single_holder[single_facet.to_s].strip.index('OR') || single_holder[single_facet.to_s].strip.index('NOT')
                           single_term = single_holder[single_facet.to_s].gsub('AND', '|||').gsub('OR', '|||').gsub('NOT', '|||')
                           single_term = single_term.split('|||')
                           single_term.map { |single_term_raw| single_term_raw.strip.delete('*') }
                         else
                           single_holder[single_facet.to_s].strip
                         end
        end
      end
      all_keywords << query_string
    end
    all_keywords.flatten
  end
end
