# Advance Search Helper
module AdvanceSearchHelper
  def self.advance_search_query_only(searched_keywords, all_queries = false, search_type = 'search_type=simple', stopwords)
    all_keywords = {}
    unless searched_keywords.blank?
      searched_keywords.each do |_, single_search|
        SearchBuilder.facets_list.each do |single_facet|
          # If value present and asked for skipping the keywords if has * with in search when exclude_wild_card is set true
          next if !single_search[single_facet.to_s].present? && single_search[single_facet.to_s].blank?
          # If Asked for first keyword only for simple search
          return single_search[single_facet.to_s] unless all_queries
          # If Asked for all keywords AND If Search conducted is simple hence expecting single search arguments
          if search_type.include?('search_type=simple')
            query_string = single_search[single_facet.to_s]
            # extracting all qouted values
            quotes_string = query_string.scan(/"([^"]*)"/).flatten
            # removing all quouted pharse from actual query string to be used as separate term
            quotes_string.each do |single_qouted_string|
              query_string = query_string.gsub('"' + single_qouted_string + '"', '')
            end
            query_string = query_string.delete('"').strip
            # Adding all qouted phrase to keywords
            quotes_string.each do |single_quotes|
              all_keywords[OpenSSL::Digest::SHA256.new.hexdigest(single_quotes)] = single_quotes.delete('"').delete("'")
            end
            # If has multiple keywords/terms in searched split and treated each term separately
            if query_string.include? ' '
              query_string.split(' ').each do |single_query|
                # ignore stopwords
                unless stopwords.include?(single_query.to_s.downcase)
                  # remove quotes and wild card search from terms
                  all_keywords[OpenSSL::Digest::SHA256.new.hexdigest(single_query)] = single_query.delete('"').delete("'").delete('*')
                end
              end
            else
              unless stopwords.include?(query_string.to_s.downcase)
                all_keywords[OpenSSL::Digest::SHA256.new.hexdigest(query_string)] = query_string.delete('"').delete("'")
              end
            end
          else
            # If Search conducted is Advance hence expecting single search arguments
            unless stopwords.include?(single_search[single_facet.to_s].to_s.downcase)
              all_keywords[OpenSSL::Digest::SHA256.new.hexdigest(single_search[single_facet.to_s])] = single_search[single_facet.to_s].delete('"').delete("'")
            end
          end
        end
        break unless all_queries
      end
    end
    if all_queries
      all_keywords
    else
      ''
    end
  end

  def multiple_search_simplifier(searched_keywords)
    pure_searched_keywords = []
    searched_keywords.each do |key, single_term|
      value_exists = false
      current_pure_term = {}
      SearchBuilder.facets_list.each do |single_facet|
        if single_term[single_facet.to_s].present? && !single_term[single_facet.to_s].blank?
          current_pure_term[:field] = single_facet.to_s
          current_pure_term[:search_query] = single_term[single_facet.to_s].gsub(/['"\\\x0]/, '\\\\\0')
          value_exists = true
        end
      end
      if value_exists
        current_pure_term[:key] = key
        current_pure_term[:op] = single_term['op']
        current_pure_term[:type_of_search] = single_term['type_of_search']
        current_pure_term[:keyword_searched] = single_term['keyword_searched']
      end
      pure_searched_keywords << current_pure_term
    end
    pure_searched_keywords
  end

  def advance_search_string(query_params)
    query_string = ''
    SearchBuilder.facets_list.each do |single_facet|
      if query_params[single_facet.to_s].present? && !query_params[single_facet.to_s].blank?
        limiter = if query_params['type_of_search'] == 'wildcard'
                    'contains'
                  elsif query_params['type_of_search'] == 'endswith'
                    'ends with'
                  elsif query_params['type_of_search'] == 'startswith'
                    'starts with'
                  else
                    'has'
                  end
        query_string += if query_params[single_facet.to_s].include?('*')
                          " #{query_params['op'].present? ? '<i>' + query_params['op'].upcase + '</i>' : ''} <span style='color: #444;font-size:14px;'>wildcard search on</span>
                             <strong>#{SearchBuilder.search_field_labels[single_facet.to_s].titleize}</strong> <i> USING </i> <strong class='title'>#{query_params['keyword_searched']}</strong>  "
                        else
                          " #{query_params['op'].present? ? '<i>' + query_params['op'].upcase + '</i>' : ''} <strong>#{SearchBuilder.search_field_labels[single_facet.to_s].titleize}</strong> <i>#{limiter}</i>
                             <strong class='title'>#{query_params['keyword_searched']}</strong> "
                        end
      end
    end
    query_string
  end
end
