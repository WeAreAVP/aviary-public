require 'rails_helper'

RSpec.describe Users::RegistrationsController, type: :controller do
	let(:user) { create(:user)}
	describe "create" do
    before :each do
	    @request.env['devise.mapping'] = Devise.mappings[:user]
	  end
    context "when role id not in params" do
	    it "has 1 as response" do
	      post :create, xhr: true, params: { user:  {"first_name"=>"test", "last_name"=>"test", "username"=>"test111", "email"=>"test@g.com", "password"=>"Testing123&U", "password_confirmation"=>"Testing123&U", "preferred_language"=>"aa", "agreement"=>"1" } }
	    	expect(JSON(response.body)['success']).to eq(true)
	    end
	  end
	  context "when role id not in params" do
	    it "has 1 as response" do
	      post :create, xhr: true, params: { user:  {"first_name"=>"test", "last_name"=>"test", "username"=>"test111", "email"=>"test@g.com", "password"=>"Testing", "password_confirmation"=>"Testing", "preferred_language"=>"aa", "agreement"=>"1" } }
	    	expect(JSON(response.body)['success']).to eq(false)
	    end
	  end
  end

  describe "update_resource" do
    before :each do
	    @request.env['devise.mapping'] = Devise.mappings[:user]
	  end
    context "when role id not in params" do
	    it "has 1 as response" do
	      controller = Users::RegistrationsController.new
	      controller.send(:update_resource, user, {first_name: 'test'})
	    end
	  end
  end
end
