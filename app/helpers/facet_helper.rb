# SearchHelper
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module FacetHelper
  def add_facet_params_to_url(url, search_facets)
    if search_facets && url
      url += '?' unless url.include?('?')
      query_params = ''
      if search_facets.key?('all') && !search_facets['all'].blank?
        search_facets['all'].each do |facet_name, facet_values|
          facet_values.each do |single_value|
            query_params += "&f[#{facet_name}][]=#{single_value}"
          end
        end
        url += query_params
      end

      if search_facets.key?('range') && !search_facets['range'].blank?
        search_facets['range'].each do |facet_name, facet_values|
          facet_values.each do |index, single_value|
            query_params += "&range[#{facet_name}][#{index}]=#{single_value}"
          end
        end
        url += query_params
      end
    end
    url
  end
end
