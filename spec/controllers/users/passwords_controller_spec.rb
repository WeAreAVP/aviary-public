require 'rails_helper'

RSpec.describe Users::PasswordsController, type: :controller do
  
  describe "create" do
    before :each do
      @request.env['devise.mapping'] = Devise.mappings[:user]
    end
    context "when role id not in params" do
      it "has 1 as response" do
        post :create, xhr: true, params: {user: {"email"=>"salman@weareavp.com"}}
        expect(JSON(response.body)['success']).to eq(false)
      end
    end
  end
end
