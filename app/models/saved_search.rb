# model/saved_search.rb
#
# SavedSearch
# The module is written to store user searches
#
# Author::    Usman Javaid  (mailto:usman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class SavedSearch < ApplicationRecord
  belongs_to :user

  validates :title, :url, presence: true
  validates :url, uniqueness: { scope: :user_id, message: 'has already been saved' }
  validates_length_of :note, maximum: 500, allow_blank: true

  def self.fetch_data(page, per_page, sort_column, sort_direction, current_user, params)
    q = params[:search][:value] if params.key?(:search)
    searching_where = '1=1'
    if q.present?
      searching_where = ['title LIKE (?) OR note LIKE (?) OR organizations.name LIKE (?)', "%#{q}%", "%#{q}%", "%#{q}%"]
    end
    saved_searches = SavedSearch.select('saved_searches.id, saved_searches.title, saved_searches.note, organizations.name as organization, saved_searches.created_at, saved_searches.updated_at, saved_searches.url')
                                .where(user_id: current_user.id)
                                .joins('LEFT JOIN organizations ON organizations.id = saved_searches.organization_id')
                                .where(searching_where)
                                .order(sort_column => sort_direction)
    count = saved_searches.size
    saved_searches = saved_searches.limit(per_page).offset((page - 1) * per_page)
    [saved_searches, count]
  end
end

