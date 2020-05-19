require "rails_helper"

RSpec.describe OrganizationUser, type: :model do
  let(:organization_user) { create(:organization_user) }

  context 'properties' do
    subject { organization_user }
    it 'should include attributes' do
      expect(subject).to have_attribute(:organization_id)
      expect(subject).to have_attribute(:user_id)
      expect(subject).to have_attribute(:role_id)
    end
  end


end