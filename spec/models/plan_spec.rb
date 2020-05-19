require "rails_helper"

RSpec.describe Plan, type: :model do
  let(:plan) { build :plan }
  context 'properties' do
    subject { create :plan }
    it 'should include attributes' do
      expect(subject).to have_attribute(:name)
      expect(subject).to have_attribute(:stripe_id)
      expect(subject).to have_attribute(:amount)
      expect(subject).to have_attribute(:frequency)
      expect(subject).to have_attribute(:max_resources)
    end
    it "returns the frequency" do
      expect(Plan.frequency(1)).to eq ('Monthly')
    end
    it "has 2 different plan types" do
      expect(Plan::Frequency.for_select.count).to eq 2
    end
    it "will return the aviary-pay-as-you-go string" do
      expect(Plan.pay_a_y_go).to eq 'aviary-pay-as-you-go'
    end
  end
end
