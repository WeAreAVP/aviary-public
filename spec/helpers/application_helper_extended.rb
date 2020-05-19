require 'rails_helper'


RSpec.describe ApplicationHelperExtended, type: :helper do
  
  let!(:user) {create(:user)}
  let!(:organization) {create(:organization, name: 'testing org', user_id: user.id)}
  let!(:registered_user) {create(:user)}
  
  # let!(:user_admin) {create(:user_as_organization_admin)}
  #
  describe 'Application Helper Extended' do
    it 'role_type' do
      expect(helper.role_type(user, organization)).to eq("organization_owner")
      expect(helper.role_type(registered_user, organization)).to eq("registered_user")
      expect(helper.role_type(nil, organization)).to eq("public_user")
    end
  end
end
