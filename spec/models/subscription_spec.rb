require "rails_helper"

RSpec.describe Subscription, type: :model do
  let(:subscription) { build :subscription }
  context 'properties' do
    subject { create :subscription }
    it 'should include attributes' do
      expect(subject).to have_attribute(:stripe_id)
      expect(subject).to have_attribute(:plan_id)
      expect(subject).to have_attribute(:last_four)
      expect(subject).to have_attribute(:card_type)
      expect(subject).to have_attribute(:current_price)
      expect(subject).to have_attribute(:start_date)
      expect(subject).to have_attribute(:renewal_date)
      expect(subject).to have_attribute(:status)
    end

  end
end
