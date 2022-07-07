#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Thesaurus
  # Thesaurus
  class Thesaurus < ApplicationRecord
    include UserTrackable
    default_scope { where('thesaurus.status' => Thesaurus.statuses[:active]) }
    belongs_to :organization
    has_many :thesaurus_thesaurus_terms, class_name: 'Thesaurus::ThesaurusTerms'

    validates_presence_of :title, :description, :status, :number_of_terms
    attr_accessor :ohms_integrations_vocabulary_file_name, :ohms_integrations_vocabulary_content_type, :ohms_integrations_vocabulary_file_size, :ohms_integrations_vocabulary_updated_at, :operation_type

    has_attached_file :ohms_integrations_vocabulary, validate_media_type: false, default_url: ''
    validates_attachment_content_type :ohms_integrations_vocabulary, content_type: ['text/csv', 'text/plain']
    enum status: %i[active in_active]
    enum operation_type: ['Overwrite Existing Terms', 'Append to Existing Terms']

    def self.all_active(organization)
      where(status: statuses[:active]).where(organization: organization)
    end

    def self.fetch_list(page, per_page, query, organization_id, export = false)
      thesaurus = Thesaurus.joins(%i[organization updated_by]) if organization_id.present?
      thesaurus = thesaurus.where('thesaurus.organization_id = ? ', organization_id)
      if query.present?
        query = query.downcase.strip
        query_string_name = 'thesaurus.title LIKE (?)'
        query_string_name_description = 'thesaurus.description LIKE (?)'
        query_string_playlist_resources_count = query.is_i? ? 'thesaurus.number_of_terms = ? ' : ' "' + Time.now.to_i.to_s + '" = ? '
        query_string_name_user = " CONCAT(users.first_name,' ', users.last_name) LIKE (?) OR CONCAT(users.first_name,' ', users.last_name) LIKE (?)"
        query_string_name_date = ' thesaurus.updated_at LIKE (?) OR thesaurus.updated_at LIKE (?)'
        thesaurus = thesaurus.where("(#{query_string_name} OR #{query_string_name_description} OR #{query_string_playlist_resources_count}) OR #{query_string_name_user} OR #{query_string_name_date}", "%#{query}%", "%#{query}%",
                                    query.to_s, "%#{query}%", query.to_s, "%#{query}%", "%#{query}%")
      end
      count = thesaurus.size
      thesaurus = thesaurus.limit(per_page).offset((page - 1) * per_page) unless export
      [thesaurus, count]
    end

    def self.list_thesaurus(org)
      [['Not Assigned', '0']] + Thesaurus.all_active(org).map { |key, _| [key.title, key.id] }
    end
  end
end
