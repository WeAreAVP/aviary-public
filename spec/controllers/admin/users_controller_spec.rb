require 'rails_helper'

RSpec.describe Admin::UsersController, type: :controller do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  before do
    sign_in(user)
    allow(controller).to receive(:authenticate_admin!).and_return(true)
  end
  describe "Get Index" do
    it "has a 200 status code" do
      get :index
      expect(response.status).to eq(200)
    end
  end
  describe "Get Pending" do
    it "has a 200 status code" do
      get :pending
      expect(response.status).to eq(200)
    end
  end
  describe "Delete Destroy" do
    it "has a 302 status code" do
      delete :destroy, params: { id: user.id }
      expect(response.status).to eq(302)
      expect(User.all).to be_empty
    end
  end
  describe "GET Add" do
    it "has a 200 status code" do
      get :new
      expect(response.status).to eq(200)
      expect(response).not_to be_redirect
    end
  end
  describe "POST Add" do
    it "has a 200 status code with errors" do
      new_user = build(:user)
      get :create, params: { user: { first_name: new_user.first_name } }
      expect(assigns(:user).errors.count).to eq(4)
    end
  end
  describe "POST Add" do
    it "has a redirect with success" do
      new_user = build(:user)
      get :create, params: { user: { first_name: new_user.first_name, last_name: new_user.last_name, username: new_user.username, email: new_user.email,
                                     password: new_user.password, password_confirmation: new_user.password_confirmation, agreement: true, preferred_language: new_user.preferred_language } }
      expect(response.status).to eq(302)
      expect(response).to be_redirect
    end
  end
  describe "GET Edit" do
    it "has a 200 status code" do
      get :edit, params: { id: user.id }
      expect(response.status).to eq(200)
      expect(response).not_to be_redirect
    end
  end
  describe "PATCH Update" do
    it "has a redirect to the list page" do
      patch :update, params: { id: user.id, user: { first_name: 'test' } }
      expect(response).to be_redirect
    end
    it "failed to update and stay on the same page" do
      patch :update, params: { id: user.id, user: { first_name: '' } }
      expect(response).not_to be_redirect
    end
  end
  describe "Create Association of the user" do
    it "has a 204 status code" do
      post :organization_create, params: { user_id: user.id, organization_id: organization.id, role_id: 1 }
      expect(response.status).to eq(204)
      expect(response).not_to be_redirect
    end
  end
  describe "Update Association of the user" do
    it "has a 204 status code" do
      post :organization_update, params: { user_id: organization.user.id, organization_id: organization.id, role_id: 1, status: false }, format: :json
      expect(response.status).to eq(202)
      expect(response).not_to be_redirect
    end
  end
  describe "Delete Association of the user" do
    it "has a 204 status code" do
      delete :organization_destory, params: { user_id: organization.user.id, org_user_id: organization.id }
      expect(response.status).to eq(302)
      expect(response).to be_redirect
    end
  end
end
