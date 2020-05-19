require "rails_helper"

RSpec.describe Ahoy::Visit, type: :model do
  
  context 'properties' do
    subject { Ahoy::Visit.new }
    it 'should include attributes' do
      expect(subject).to have_attribute(:visit_token)
      expect(subject).to have_attribute(:visitor_token)
      expect(subject).to have_attribute(:user_id)
      expect(subject).to have_attribute(:landing_page)
      expect(subject).to have_attribute(:region)
    end
    it 'triger save' do
      Ahoy::Visit.new.save()
    end
  end
end