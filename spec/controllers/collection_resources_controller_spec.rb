require 'rails_helper'
RSpec.describe CollectionResourcesController, type: :controller do
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
      get :show, params: { collection_id: collection_resource.collection.id, collection_resource_id: collection_resource.id.to_s }
      expect(response.status).to eq(200)
    end
  end

  describe "GET Show Search Counts" do
    it "has a 200 status code" do
      collection_resource_file.save
      get :show_search_counts, params: { collection_id: collection_resource.collection.id, collection_resource_id: collection_resource.id.to_s, resource_file_id: collection_resource_file.id }
      expect(response.status).to eq(200)
    end
  end

  describe "GET Index" do
    it "has a 200 status code" do
      get :index, params: {}
      expect(response.status).to eq(200)
    end
  end

  describe "GET load_resource_details_template" do
    it "has a 200 status code" do
      collection_resource_file.save
      get :edit, params: { "av_resource_id" => collection_resource.id, "collection_id" => collection_resource.collection.id, "collection_resource_id" => collection_resource.id, "resource_file_id" => collection_resource_file.id }
      expect(response.status).to eq(200)
    end
  end

  describe "GET delete_resource_file" do
    it "has a 200 status code" do
      collection_resource_file.save
      get :delete_resource_file, params: { "av_resource_id" => collection_resource.id, "collection_id" => collection_resource.collection.id, "collection_resource_id" => collection_resource.id, "resource_file_id" => collection_resource_file.id }
      expect(response.status).to eq(302)
    end
  end

  describe "PATCH Index" do
    it "has a 200 status code" do
      fields = Aviary::FieldManagement::OrganizationFieldManager.new.organization_field_settings(collection_resource.collection.organization, nil, 'resource_fields', 'sort_order')
      updated_values = {}
      fields.each_with_index do |(system_name, _single_collection_field), _index|
        updated_values[system_name] ||= {}
        updated_values[system_name]['values'] ||= []
        updated_values[system_name]['system_name'] = system_name
        value = "dummy title"
        updated_values[system_name]['values'] << { "vocab_value" => "", "value" => value, "collection_resource_id" => collection_resource.id }
      end
      patch :update_metadata, params: { "resource_file_id" => "1", "collection_resource" => { "collection_resource_field_values" => updated_values }, "collection_id" => collection_resource.collection.id, "collection_resource_id" => collection_resource.id }
      expect(assigns(:msg)).to eq("Resource description metadata has been updated successfully.")
      expect(response.status).to eq(302)
    end
  end

  describe "GET load_head_and_tombstone_template" do
    it "has a 200 status code" do
      get :load_head_and_tombstone_template, params: { "collection_id" => "1", "collection_resource_id" => "1" }
      expect(response.status).to eq(200)
    end
  end

  describe "GET load_resource_details_template" do
    it "has a 200 status code" do
      collection_resource_file.save
      get :load_resource_details_template, params: { "tabs_size" => "12", "search_size" => "12", "collection_id" => "1", "collection_resource_id" => "1", "resource_file_id" => "1" }
      expect(response.status).to eq(200)
    end
  end

  describe "Delete Destroy" do
    it "has a 302 status code" do
      delete :destroy, params: { id: collection_resource.id }
      expect(response.status).to eq(302)
      expect(CollectionResource.all).to be_empty
    end
  end

  describe "Delete Destroy" do
    it "has a 302 status code" do
      delete :destroy, params: { id: collection_resource.id }
      expect(response.status).to eq(302)
      expect(CollectionResource.all).to be_empty
    end
  end

  describe "POST Save Update File Name" do
    it "has a 302 status code" do
      collection_resource_file.save()
      post :update_file_name, params: { collection_id: collection_resource.collection.id, collection_resource_file_id: collection_resource.collection_resource_files.first.id, collection_resource_id: collection_resource.id,
                                        collection_resource: { title: 'testing' }
      }
      expect(response.status).to eq(302)
    end
  end

  describe "POST Save Update Thumbnail" do
    it "has a 302 status code" do
      collection_resource_file.save()
      post :update_thumbnail, params: { collection_id: collection_resource.collection.id, collection_resource_file_id: collection_resource.collection_resource_files.first.id, collection_resource_id: collection_resource.id,
                                        collection_resource_file: { thumbnail: File.new("#{Rails.root}/spec/fixtures/abc.png") }
      }
      expect(response.status).to eq(302)
    end
  end

  describe "POST Save Resource File" do
    it "has a 302 status code with with 1 file count when using file_url" do
      post :save_resource_file, params: { collection_id: collection_resource.collection.id, collection_resource_id: collection_resource.id,
                                          collection_resource: { file_url: 'https://www.weareavp.com/small.mp4', is_3d: false }
      }
      expect(response.status).to eq(302)
      expect(collection_resource.collection_resource_files.size).to eq(1)
    end
    #it "has a 302 status code with with 1 file count when using embed code" do
    #  post :save_resource_file, params: { collection_id: collection_resource.collection.id, collection_resource_id: collection_resource.id,
    #                                      collection_resource: { embed_code: collection_resource_file_vimeo.embed_code, embed_type: collection_resource_file_vimeo.embed_type }
    #  }
    #  expect(response.status).to eq(302)
    #  expect(collection_resource.collection_resource_files.size).to eq(1)
    #end
    it "has a 302 status code with with 1 file count when using youtube embed code" do
      post :save_resource_file, params: { collection_id: collection_resource.collection.id, collection_resource_id: collection_resource.id,
                                          collection_resource: { embed_code: collection_resource_file_youtube.embed_code, embed_type: collection_resource_file_youtube.embed_type }
      }
      expect(response.status).to eq(302)
      expect(collection_resource.collection_resource_files.size).to eq(1)
    end
    it "has a 302 status code with with 1 file count when using file upload" do
      post :save_resource_file, params: { collection_id: collection_resource.collection.id, collection_resource_id: collection_resource.id,
                                          av_resource: { resource_files: [sample_file] }, is_3d: []
      }
      expect(response.status).to eq(302)
      expect(collection_resource.collection_resource_files.size).to eq(1)
    end
  end
end
