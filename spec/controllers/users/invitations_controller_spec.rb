require 'rails_helper'

RSpec.describe Users::InvitationsController, type: :controller do
  
  describe "create" do
    before :each do
      @request.env['devise.mapping'] = Devise.mappings[:user]
    end
  end
end
