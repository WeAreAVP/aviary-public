# PublicAccessUrl
class PublicAccessUrl < ApplicationRecord
  belongs_to :collection_resource

  scope :ever_green_url, -> { where(access_type: 'ever_green_url', status: true) }
  scope :limited_access_url, -> { where(access_type: 'limited_access_url', status: true) }

  def self.fetch_data(page, per_page, sort_column, sort_direction, params, current_organization_id)
    q = params[:search][:value] if params.key?(:search)
    searching_where = '1=1'
    if q.present?
      searching_where = ['collection_resources.title LIKE (?) OR public_access_urls.access_type LIKE (?) OR url LIKE (?) OR collections.title LIKE (?)',
                         "%#{q}%", "%#{q}%", "%#{q}%", "%#{q}%"]
    end
    public_access_url = PublicAccessUrl.select('public_access_urls.id, access_type, duration, url, collection_resources.id as collection_resource_id, collection_resources.collection_id, collection_resources.title,
                                                collections.title as collection_name, public_access_urls.created_at, public_access_urls.status, public_access_urls.updated_at, public_access_urls.information ')
                                       .joins('INNER JOIN collection_resources ON collection_resources.id = public_access_urls.collection_resource_id')
                                       .joins('INNER JOIN collections ON collections.id = collection_resources.collection_id')
                                       .where('collections.organization_id = ?', current_organization_id)
                                       .where(searching_where)
                                       .order(sort_column => sort_direction)
    count = public_access_url.size
    public_access_url = public_access_url.limit(per_page).offset((page - 1) * per_page)
    [public_access_url, count]
  end
end
