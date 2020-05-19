require 'rails_helper'

RSpec.describe Users::ConfirmationsController, type: :controller do
  let(:user) { create(:user)}
  describe "update_resource" do
    before :each do
      @request.env['devise.mapping'] = Devise.mappings[:user]
    end
    context "when role id not in params" do
      it "has 1 as response" do
        
      end
    end
  end
end
