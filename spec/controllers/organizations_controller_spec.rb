require 'rails_helper'
require 'action_view'
RSpec.describe OrganizationsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:organization_user) { create(:organization_user, token: 'fsdhfabkjahdf') }
  let!(:plan) { create(:plan) }
  let!(:yearly) { create(:plan, frequency: 2) }
  before do
    allow(controller).to receive(:current_organization).and_return(organization)
    @request.host = "#{organization.url}.test.host"
    allow(controller).to receive(:current_user).and_return(organization.user)
    sign_in(organization.user)
    allow(controller).to receive(:authenticate_user!).and_return(true)
  end
  describe "Organization Controller" do
    it "has a 200 status code when open edit organization page" do
      get :edit
      expect(response.status).to eq(200).or eq(302)
    end
    
    it "has a 200 status code when display_settings" do
      get :display_settings
      expect(response.status).to eq(200).or eq(302)
    end
    
    
    it "has a 302 status code when open edit organization with correct info" do
      post :update, params: { id: organization.id,
                              organization: { name: organization.name, url: organization.url,
                                              description: organization.description, address_line_1: organization.address_line_1, city: organization.city,
                                              state: organization.state, country: organization.country, zip: organization.zip } }
      expect(response.status).to eq(200).or eq(302)
    end
    it "has a 200 status code when open edit organization with incorrect info and empty body" do
      post :update, params: { id: organization.id,
                              organization: { name: '', url: organization.url,
                                              description: organization.description } }
      expect(response.status).to eq(200).or eq(302)
    end


    it "has a 200 status code when open edit organization with incorrect info and empty body" do
      allow(controller).to receive(:current_organization).and_return(organization)
      post :update_resource_column_sort, xhr: true, params: { id: organization.id }, format: :json
      expect(JSON(response.body)['errors']).to eq(false)
    end

    context "when token present" do
      it "has a 200 status code when open edit organization with incorrect info and empty body" do
        allow(controller).to receive(:current_organization).and_return(organization)
        get :confirm_invite, xhr: true, params: { token:  organization_user.token}
        expect(flash[:notice]).to be_present
        expect(flash[:notice]).to eq('Your new status has been confirmed!')
      end
    end

    context "when token not present" do
      it "has a 200 status code when open edit organization with incorrect info and empty body" do
        allow(controller).to receive(:current_organization).and_return(organization)
        get :confirm_invite, xhr: true, params: { token: 'vmmmmmyu'}
        expect(flash[:notice]).to be_present
        expect(flash[:notice]).to eq('Not a valid confirmation token.')
      end
    end
  end
end