require 'rails_helper'
RSpec.describe CollectionResourceFilesController, type: :controller do
  include Aviary::ResourceFileManagement
  include Devise::Test::ControllerHelpers
  let(:collection_resource) { create(:collection_resource) }
  let(:collection_resource_failed) { create :collection_resource, attributes_for(:collection_resource, :not_public) }
  let(:collection_resource_file_vimeo) { build :collection_resource_file, attributes_for(:collection_resource_file, :check_vimeo) }
  let(:collection_resource_file_youtube) { build :collection_resource_file, attributes_for(:collection_resource_file, :check_embed) }
  let(:subscription) { build :subscription }
  let(:collection_resource_file) { build :collection_resource_file, collection_resource: collection_resource }
  let(:sample_file) { fixture_file_upload("#{Rails.root}/spec/fixtures/small.mp4", 'video/mp4') }
  
  before do
    request[:subdomain] = collection_resource.collection.organization.url
    allow(controller).to receive(:current_organization).and_return(collection_resource.collection.organization)
    allow(controller).to receive(:current_user).and_return(collection_resource.collection.organization.user)
    subscription.organization = collection_resource.collection.organization
    subscription.save
    sign_in(collection_resource.collection.organization.user)
    allow(controller).to receive(:authenticate_user!).and_return(true)
  end
  describe "GET Show" do
    it "has a 200 status code" do
      get :index, params: { collection_id: collection_resource.collection.id, collection_resource_id: collection_resource.id.to_s, collection_resource_file_id: collection_resource_file_vimeo.id }
      expect(response.status).to eq(200)
    end
  end
  describe "GET bulk_resource_file_edit" do
    it "has a 200 status code" do
      get :bulk_resource_file_edit, params: { collection_id: collection_resource.collection.id, collection_resource_id: collection_resource.id.to_s, collection_resource_file_id: collection_resource_file_vimeo.id, check_type: 'bulk_delete'  }, format: :json
      expect(response.status).to eq(200)
    end
  end
  
  describe "GET bulk_resource_file_edit" do
    it "has a 200 status code" do
      get :bulk_resource_file_edit, params: { collection_id: collection_resource.collection.id, collection_resource_id: collection_resource.id.to_s, collection_resource_file_id: collection_resource_file_vimeo.id, check_type: 'bulk'  }, format: :json
      expect(response.status).to eq(200)
    end
  end

  describe "GET export_resource_file" do
    it "has a 302 status code" do
      get :export_resource_file, params: { search: {value: ''}, collection_id: collection_resource.collection.id, collection_resource_id: collection_resource.id.to_s, collection_resource_file_id: collection_resource_file_vimeo.id, check_type: 'bulk'  }
      expect(response.status).to eq(302)
    end
  end
end
