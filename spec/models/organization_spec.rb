require "rails_helper"

RSpec.describe Organization, type: :model do
  let(:role_owner) { create(:role, system_name: 'organization_owner') }
  let(:role_admin) { create(:role, system_name: 'organization_admin') }
  let(:role_user) { create(:role, system_name: 'organization_user') }
  let(:organization) { create(:organization) }
  context 'properties' do
    subject { build :organization }
    it 'should include attributes' do
      expect(subject).to have_attribute(:name)
      expect(subject).to have_attribute(:user_id)
      expect(subject).to have_attribute(:url)
      expect(subject).to have_attribute(:description)
      expect(subject).to have_attribute(:address_line_1)
      expect(subject).to have_attribute(:city)
      expect(subject).to have_attribute(:state)
      expect(subject).to have_attribute(:country)
      expect(subject).to have_attribute(:zip)
      expect(subject).to have_attribute(:status)
      expect(subject).to have_attribute(:display_banner)
      expect(subject).to have_attribute(:logo_image_file_name)
      expect(subject).to have_attribute(:banner_image_file_name)
      expect(subject).to have_attribute(:storage_type)
    end
  end

  describe '#organization_owners' do
    context 'Get list of organization owners' do
      subject { organization.organization_owners }
      it 'will return same organization user' do
        expect(subject).to be_truthy
        expect(subject.first.organization_id).to be(organization.id)
      end
    end
  end

  describe '#current_user_org_owner' do
    context 'Get list of organization owners' do
      subject { organization.current_user_org_owner(organization.user) }
      it 'will return same organization user' do
        expect(subject).to be_truthy
        expect(subject.first.organization_id).to be(organization.id)
      end
    end
  end

  describe '#resource_count' do
    context 'get count of resource for the organization' do
      before { organization }
      subject { organization.resource_count }
      it 'will return same count' do
        expect(subject).to be(0)
      end
    end
  end
end
