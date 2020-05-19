require "rails_helper"

RSpec.describe Collection, type: :model do
  let!(:user) { create(:user) }
  let!(:organization) { create(:organization, name: 'testing org', user_id: user.id) }
  let!(:collection) { create(:collection, title: 'testing collection', organization: organization) }
  let!(:collection_resource) { create(:collection_resource, title: 'testing resource', collection: collection) }

  let!(:collection_resource_file) { create(:collection_resource_file, collection_resource: collection_resource) }
  let!(:file_index) { create(:file_index, collection_resource_file: collection_resource_file) }
  let!(:file_index_point) { create(:file_index_point, file_index: file_index) }
  
  let!(:collection_resource_file) { create(:collection_resource_file, collection_resource: collection_resource) }
  let!(:file_transcript) { create(:file_transcript, collection_resource_file: collection_resource_file) }
  
  let!(:file_transcript_point) { create(:file_transcript_point, file_transcript: file_transcript) }
  
  context 'properties' do
    it 'should include attributes' do
      collection_resource.reindex_collection_resource
    end
  end
end
