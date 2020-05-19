require "rails_helper"

RSpec.describe Role, type: :model do


  context 'properties' do
    subject { build :role }
    it 'should include attributes' do
      expect(subject).to have_attribute(:system_name)
      expect(subject).to have_attribute(:name)
      expect(Role.organization_roles).to be_empty
      expect(Role.role_organization_owner).to be_nil
      expect(Role.organization_role_ids).to be_empty
      create(:role_organization_admin)
      create(:role_organization_user)
      expect(Role.organization_admin_or_user.size).to eq(2)
    end
  end
end
