# Search Presenter
# Author::  Furqan Wasi(mailto:furqan@weareavp.com)
class SearchPresenter < BasePresenter
  class << self
    # @param [Object] current_user
    # @param [Object] current_organization
    # @return Hash
    def org_n_collection_facet_manager(current_organization, current_user, user_ip, current_params, params_default, check_array, has_values)
      solr_manager = SolrSearchManagement.new
      solr_parameters = { 'facet.field' => [], 'facet' => true, 'fl' => 'id_is' }
      solr_parameters['facet.field'] << params_default[:facet] if params_default[:facet].present?
      solr_parameters[:fq] = []
      solr_parameters = SearchBuilder.default_fqs(current_organization, user_ip, current_user, solr_parameters)
      if current_params[:f].present? && has_values
        current_params[:f].each do |index, single_fq|
          next if check_array.include?(index)
          single_fq.each do |single_fq_value|
            solr_parameters[:fq] << (single_fq_value.scan(/['"']/).present? ? "{!term f=#{index}}#{single_fq_value}" : "#{index}:\"#{single_fq_value}\"")
          end
        end
      end
      solr_parameters[:fq] << params_default[:fq] if params_default[:fq].present?
      solr_parameters[:q] = params_default[:last_fq] if params_default[:last_fq].present?
      solr_manager.select_query(solr_parameters)
    end
  end

  def self.organization_facet_manager(current_organization, current_user, user_ip, current_params, has_values, last_fq)
    fq = "collection_id_is:(#{current_params[:f][:collection_id_is].join(' OR ')})" if current_params[:f].present? && current_params[:f][:collection_id_is].present?
    default_params = { facet: '{!ex=organization_id_is-tag}organization_id_is', fq: fq }
    default_params[:last_fq] = last_fq.present? ? last_fq : false
    org_n_collection_facet_manager(current_organization, current_user, user_ip, current_params, default_params, %w[collection_id_is organization_id_is], has_values)
  end

  def self.collection_facet_manager(current_organization, current_user, user_ip, current_params, has_values, last_fq)
    fq = "organization_id_is:(#{current_params[:f][:organization_id_is].join(' OR ')})" if current_params[:f].present? && current_params[:f][:organization_id_is].present?
    default_params = { facet: '{!ex=collection_id_is-tag}collection_id_is', fq: fq }
    default_params[:last_fq] = last_fq.present? ? last_fq : false
    org_n_collection_facet_manager(current_organization, current_user, user_ip, current_params, default_params, %w[collection_id_is organization_id_is], has_values)
  end
end
