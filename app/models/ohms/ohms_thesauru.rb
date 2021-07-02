# Ohms
module Ohms
  # OhmsThesauru
  class OhmsThesauru < ApplicationRecord
    include UserTrackable

    belongs_to :organization
    validates_presence_of :title, :description, :status, :thesaurus_terms, :status, :number_of_terms
    attr_accessor :ohms_integrations_vocabulary_file_name, :ohms_integrations_vocabulary_content_type, :ohms_integrations_vocabulary_file_size, :ohms_integrations_vocabulary_updated_at, :operation_type

    has_attached_file :ohms_integrations_vocabulary, validate_media_type: false, default_url: ''
    validates_attachment_content_type :ohms_integrations_vocabulary, content_type: ['text/csv', 'text/plain']
    enum status: %i[active in_active]
    enum operation_type: ['Overwrite Existing Terms', 'Append to Existing Terms']

    def self.fetch_list(page, per_page, query, organization_id, export = false)
      thesaurus = OhmsThesauru.joins(%i[organization updated_by]) if organization_id.present?
      thesaurus = thesaurus.where('ohms_thesaurus.organization_id = ? ', organization_id)
      if query.present?
        query = query.downcase.strip
        query_string_name = 'ohms_thesaurus.title LIKE (?)'
        query_string_name_description = 'ohms_thesaurus.description LIKE (?)'
        query_string_playlist_resources_count = query.is_i? ? 'ohms_thesaurus.number_of_terms = ? ' : ' "' + Time.now.to_i.to_s + '" = ? '
        query_string_name_user = " CONCAT(users.first_name,' ', users.last_name) LIKE (?) OR CONCAT(users.first_name,' ', users.last_name) LIKE (?)"
        query_string_name_date = ' ohms_thesaurus.updated_at LIKE (?) OR ohms_thesaurus.updated_at LIKE (?)'
        thesaurus = thesaurus.where("(#{query_string_name} OR #{query_string_name_description} OR #{query_string_playlist_resources_count}) OR #{query_string_name_user} OR #{query_string_name_date}", "%#{query}%", "%#{query}%",
                                    query.to_s, "%#{query}%", query.to_s, "%#{query}%", "%#{query}%")
      end
      count = thesaurus.size
      thesaurus = thesaurus.limit(per_page).offset((page - 1) * per_page) unless export
      [thesaurus, count]
    end
  end
end
