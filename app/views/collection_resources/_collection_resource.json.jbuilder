json.extract! collection_resource, :id, :created_at, :updated_at
json.url collection_collection_resource_url(collection_resource.collection, collection_resource, format: :json)
