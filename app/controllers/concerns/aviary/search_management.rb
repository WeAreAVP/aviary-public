# controllers/concerns/bulk_operation.rb
# Module Aviary::BulkOperation
# The module is written to do bulk operation
#
# Author:: Furqan Wasi  (mailto:furqan@weareavp.com)
module Aviary::SearchManagement
  extend ActiveSupport::Concern

  def search_text
    @av_resource = CollectionResource.find(params[:collection_resource_id])
    if params.key?('remove_search_text') && params.key?('identifier') && params['remove_search_text'] == 'true'
      if params['identifier'] == 'all'
        session[:search_text]["search_text_#{params[:collection_resource_id]}"] = {}
      elsif session[:search_text]["search_text_#{params[:collection_resource_id]}"].present?
        session[:search_text]["search_text_#{params[:collection_resource_id]}"].delete(params['identifier'])
      end
    else
      session[:search_text] ||= {}
      session[:search_text]["search_text_#{params[:collection_resource_id]}"] ||= {}
      if params[:search].present? && params[:search][:text].present?
        search_text = params[:search][:text]
        search_text = search_text.delete('*').delete('"').delete("'")
        session[:search_text]["search_text_#{params[:collection_resource_id]}"][OpenSSL::Digest::SHA256.new.hexdigest(search_text)] = search_text
      end
      session[:search_text]["selected_index_#{params[:collection_resource_id]}"] = {} unless session[:search_text].key?("selected_index_#{params[:collection_resource_id]}")
      session[:search_text]["selected_transcript_#{params[:collection_resource_id]}"] = {} unless session[:search_text].key?("selected_transcript_#{params[:collection_resource_id]}")
      session[:search_text]["selected_transcript_#{params[:collection_resource_id]}"][params[:selected_file]] = params[:selected_transcript]
      session[:search_text]["selected_index_#{params[:collection_resource_id]}"][params[:selected_file]] = params[:selected_index]
    end
    redirect_back(fallback_location: root_path)
  end
end
