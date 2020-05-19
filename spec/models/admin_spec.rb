require "rails_helper"

RSpec.describe Admin, type: :model do
  let!(:admin) { create(:admin) }

  context 'properties' do
    subject { build :admin }
    it 'should include attributes' do
      expect(subject).to have_attribute(:first_name)
      expect(subject).to have_attribute(:last_name)
      expect(subject).to have_attribute(:email)
      expect(subject).to have_attribute(:agreement)
      expect(subject).to have_attribute(:preferred_language)
    end
  end
end