require 'rails_helper'
RSpec.describe IndexesController, type: :controller do
  include ApplicationHelper
  let(:file_index) { create(:file_index) }
  before do
    request[:subdomain] = file_index.collection_resource_file.collection_resource.collection.organization.url
    allow(controller).to receive(:current_organization).and_return(file_index.collection_resource_file.collection_resource.collection.organization)
    allow(controller).to receive(:current_user).and_return(file_index.collection_resource_file.collection_resource.collection.organization.user)
    sign_in(file_index.collection_resource_file.collection_resource.collection.organization.user)
    allow(controller).to receive(:authenticate_user!).and_return(true)
  end
  describe "POST Create" do
    it "has a 200 status code with no error on index create" do
      post :create, params: { resource_file_id: file_index.collection_resource_file.id,
                              file_index: { title: file_index.title, associated_file: fixture_file_upload("#{Rails.root}/spec/fixtures/valid_sample_xml.xml", 'application/xml'),
                                            is_public: file_index.is_public, language: file_index.language } },
           format: :json
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)[0]['errors']).to be_empty
    end
    it "has a 200 status code with no error on index delete and then create" do
      post :create, params: { resource_file_id: file_index.collection_resource_file.id, file_index_id: file_index.id,
                              file_index: { title: file_index.title, associated_file: fixture_file_upload("#{Rails.root}/spec/fixtures/valid_sample_xml.xml", 'application/xml'),
                                            language: file_index.language, is_public: file_index.is_public } },
           format: :json
      expect(JSON.parse(response.body)[0]['errors']).to be_empty
      expect(response.status).to eq(200)
    end
    it "has a 200 status code with error" do
      post :create, params: { resource_file_id: file_index.collection_resource_file.id,
                              file_index: { title: '', associated_file: fixture_file_upload("#{Rails.root}/spec/fixtures/valid_sample_xml.xml", 'application/xml'),
                                            is_public: file_index.is_public, language: file_index.language } },
           format: :json
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)[0]['errors']).not_to be_empty
    end
  end
  describe "PATCH Sort" do
    it "has a 200 status code with no error" do
      post :sort, params: { resource_file_id: file_index.collection_resource_file.id,
                            sort_list: [file_index.id] },
           format: :json
      expect(response.status).to eq(200)
    end
  end
  describe "Delete destroy" do
    it "has a 200 status code with no error" do
      delete :destroy, params: { id: file_index.id }
      expect(response.status).to eq(302)
    end
  end
end
