require 'rails_helper'

RSpec.describe UsersController, type: :controller do
	let(:organization) { create(:organization) }
	let(:role_organization_admin) { create(:role_organization_admin)}
	let(:user1) { create(:user, email: 'hellow1test@gmail.com')}

	before do
		request[:subdomain] = organization.url
		allow(controller).to receive(:current_organization).and_return(organization)
		allow(controller).to receive(:current_user).and_return(organization)
		sign_in(organization.user)
		allow(controller).to receive(:authenticate_user!).and_return(true)
	end

	describe "change_org_status" do
    context "when role id not in params" do
	    it "has 1 as response" do
	      get :change_org_status, xhr: true, params: { user_id: organization.user.id, org_id: organization.id }
	      expect(JSON(response.body).first['response']).to eq(1)
	    end

	    it "role id is" do
	      get :change_org_status, xhr: true, params: { user_id: organization.user.id, org_id: organization.id }
	      expect(organization.organization_users.first.role_id).to eq(1)
	    end
	  end

	  context "when role id is in params" do
	    it "role id is" do
	      get :change_org_status, xhr: true, params: { user_id: organization.user.id, org_id: organization.id, role_id: role_organization_admin.id }
	      expect(organization.organization_users.first.role_id).to eq(role_organization_admin.id)
	    end
	  end
  end

  describe "index" do
    context "when role id not in params" do
	    it "has 1 as response" do
	      get :index, xhr: true
	      expect(assigns(:roles).first.system_name).to eq('organization_owner')
	    end
	  end
  end

	describe "add_new_member" do
		context "when role id not in params" do
			it "has 1 as response" do
				post :add_new_member, xhr: true, params: { user_id: organization.user.id, 'user' => [ {'search'=> 'hellow1test@gmail.com', 'user_role'=> role_organization_admin.id }]}
				expect(JSON(response.body)['status']).to eq('success')
			end
		end
	end
  describe "destroy" do
    context "when role id not in params" do
	    it "has 1 as response" do
	      delete :destroy, xhr: true, params: { id: organization.user.id }
	      expect(OrganizationUser.count).to eq(0)
	    end
	  end
  end

  describe "remove_user" do
    context "when role id not in params" do
	    it "has 1 as response" do
	      get :remove_user, xhr: true, params: { user_id: organization.user.id, organization_id: organization.id }
	      expect(OrganizationUser.count).to eq(0)
	    end
	  end
  end
end
