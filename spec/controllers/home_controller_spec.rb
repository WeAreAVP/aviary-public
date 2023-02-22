require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  let(:collection) { create(:collection) }
  describe "POST set_layout" do
    it "has a 200 status code with success" do
      post :set_layout, params: { layout: 'main_collapsed' },
           format: :json
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['status']).to eq('success')
    end
  end
  describe "GET index" do
    it "has a 200 status code" do
      get :index
      expect(response.status).to eq(200)
    end
  end

  describe "GET get_organization" do
    it "has a 200 status code with current organization" do
      organization = create(:organization)
      allow(controller).to receive(:current_organization).and_return(organization)
      allow(controller).to receive(:current_user).and_return(organization)
      get :featured_organization
      expect(response.status).to eq(200)
    end

  end

  describe "GET get_collections" do
    it "has a 200 status code with current organization" do
      organization = create(:organization)
      allow(controller).to receive(:current_organization).and_return(organization)
      allow(controller).to receive(:current_user).and_return(organization.user)
      get :featured_collections
      expect(response.status).to eq(200)
    end

    it "has a 200 status code with current organization" do
      organization = create(:organization, status: true)
      allow(controller).to receive(:current_organization).and_return(organization)
      get :featured_collections
      expect(response.status).to eq(200)
    end
    

    it "with no current organization" do
      organization = create(:organization, status: true)
      collection = create(:collection, organization_id: organization.id, is_featured: true)
      allow(controller).to receive(:current_organization).and_return(organization)
      allow(controller).to receive(:current_user).and_return(organization.user)
      get :featured_collections
      expect(response.status).to eq(200)
      expect(assigns(:featured_collections).first).to eq(collection)
    end
  end

  describe "GET get_resources" do
    it "has a 200 status code with current organization" do
      organization = create(:organization)
      allow(controller).to receive(:current_organization).and_return(organization)
      allow(controller).to receive(:current_user).and_return(organization.user)
      get :featured_resources
      expect(response.status).to eq(200)
    end

    it "when resource file is nil" do
      organization = create(:organization, status: true)
      collection = create(:collection, organization_id: organization.id, is_featured: true)
      collection_resource = create(:collection_resource, title: 'testing resource', collection: collection , is_featured: true)
      allow(controller).to receive(:current_organization).and_return(organization)
      allow(controller).to receive(:current_user).and_return(organization.user)
      get :featured_resources
      expect(response.status).to eq(200)
      expect(assigns(:featured_resources)).to be_empty
    end
  end
  
  describe "GET forbidden" do
    it "has a 200 status code" do
      get :forbidden
      expect(response.status).to eq(200)
    end
  end
  describe "GET not_found" do
    it "has a 200 status code" do
      get :not_found
      expect(response.status).to eq(200)
    end
  end
  describe "GET terms_of_service" do
    it "has a 200 status code" do
      get :terms_of_service
      expect(response.status).to eq(200)
    end
  end
  describe "GET about" do
    it "has a 200 status code" do
      get :about
      expect(response.status).to eq(200)
    end
  end
  describe "GET features" do
    it "has a 200 status code" do
      get :features
      expect(response.status).to eq(200)
    end
  end

  describe "GET noid" do
    it "has a 302 status code" do
      collection_resource = create(:collection_resource)
      get :noid, params: { noid: collection_resource.noid }
      expect(response.status).to eq(302)
    end
  end
end
