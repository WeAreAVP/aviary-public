require "rails_helper"

RSpec.describe Ahoy::Event, type: :model do
  
  context 'properties' do
    subject { Ahoy::Event.new }
    it 'should include attributes' do
      expect(subject).to have_attribute(:visit_id)
      expect(subject).to have_attribute(:user_id)
      expect(subject).to have_attribute(:name)
      expect(subject).to have_attribute(:properties)
      expect(subject).to have_attribute(:time)
    end
  end
end