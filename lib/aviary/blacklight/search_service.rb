# # frozen_string_literal: true
class Aviary::Blacklight::SearchService < Blacklight::SearchService
  def search_results
    builder = search_builder.with(search_state)
    builder.current_params = search_state.params if search_state.params.present?
    builder.session_solr = search_state.params['session_solr']
    builder.current_user = search_state.params['current_user']
    builder.current_organization = search_state.params['current_organization']
    builder.user_ip = search_state.params['user_ip']
    builder.request_is_xhr = search_state.params['request_is_xhr']
    builder.resource_list = search_state.params['resource_list']
    builder.myresources = search_state.params['myresources']
    builder.page = search_state.page
    builder.rows = search_state.per_page
    builder = yield(builder) if block_given?
    response = repository.search(builder)

    if response.grouped? && grouped_key_for_results
      [response.group(grouped_key_for_results), []]
    elsif response.grouped? && response.grouped.length == 1
      [response.grouped.first, []]
    else
      [response, response.documents]
    end
  end
end
