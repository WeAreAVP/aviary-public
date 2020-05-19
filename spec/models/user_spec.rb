require "rails_helper"

RSpec.describe User, type: :model do
  let(:user) { create(:user) }
  let(:role_owner) { create(:role, system_name: 'organization_owner') }
  let(:role_admin) { create(:role, system_name: 'organization_admin') }
  let(:role_user) { create(:role, system_name: 'organization_user') }
  let(:organization) { create(:organization) }
  context 'properties' do
    subject { user }
    it 'should include attributes' do
      expect(subject).to have_attribute(:first_name)
      expect(subject).to have_attribute(:last_name)
      expect(subject).to have_attribute(:email)
      expect(subject).to have_attribute(:agreement)
      expect(subject).to have_attribute(:status)
      expect(subject).to have_attribute(:updated_by_id)
      expect(subject).to have_attribute(:created_by_id)
    end
  end

  describe '#current_org_owner_admin' do
    context 'when user is the owner of organization' do
      before { user.organization_users.create(organization_id: organization.id, role_id: role_owner.id) }
      subject { user.current_org_owner_admin(organization) }
      it 'will return same organization user' do
        expect(subject.first.user.id).to be(user.id)
      end
    end
    context 'when user is the admin of organization' do
      before { user.organization_users.create(organization_id: organization.id, role_id: role_admin.id) }
      subject { user.current_org_owner_admin(organization) }
      it 'will return same organization user' do
        expect(subject.first.user.id).to be(user.id)
      end
    end
  end

  describe '#current_org_owner' do
    context 'when user is the owner of organization' do
      before { user.organization_users.create(organization_id: organization.id, role_id: role_owner.id) }
      subject { user.current_org_owner(organization) }
      it 'will return same organization user' do
        expect(subject.first.user.id).to be(user.id)
      end
    end
  end

  describe '#full_name' do
    context 'when user first name and last name matched' do
      subject { user.full_name }
      it 'will return first and last name' do
        expect(subject).to match("#{user.first_name} #{user.last_name}")
      end
    end
    context 'when user first name and last name not matched' do
      subject { user.full_name }
      it 'will not return same name' do
        expect(subject).not_to match("#{user.last_name} #{user.first_name}")
      end
    end
  end

  describe '#full_name' do
    context 'when user first name and last name matched' do
      subject { user.full_name_with_email }
      it 'will return first last name and email' do
        expect(subject).to match("#{user.first_name} #{user.last_name} ( #{user.email} )")
      end
    end
    context 'when user first name and last name not matched' do
      subject { user.full_name_with_email }
      it 'will not return same name' do
        expect(subject).not_to match("#{user.last_name} #{user.first_name} ( #{user.email} )")
      end
    end
  end

  describe '#fetch_user_list' do
    context 'when current_organization present' do
      before { user.organization_users.create(organization_id: organization.id, role_id: role_owner.id) }
      subject { User.fetch_user_list(user, 1, 10, 'email', 'asc', { search: { value: 'user' } }, organization) }
      it 'will return same organization user' do
        expect(subject.first.first.organization_id).to be(organization.id)
      end
    end
  end
  describe '#fetch_user_list' do
    context 'when current_organization present and search param' do
      before { user.organization_users.create(organization_id: organization.id, role_id: role_owner.id) }
      subject { User.fetch_user_list(user, 1, 10, 'email', 'asc', { search: { q: 'first' } }, organization) }
      it 'will return same organization user' do
        expect(subject.first.first.organization_id).to be(organization.id)
      end
    end
  end
  describe '#admin_user_list' do
    context 'when admin list the users' do
      before { user = create(:user) }
      subject { User.admin_user_list(1, 10, 'email', 'asc', { search: { value: 'user' } }) }
      it 'will return users list' do
        expect(subject.second).to eq(1)
      end
    end
  end
end