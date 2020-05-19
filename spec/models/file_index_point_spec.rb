require "rails_helper"

RSpec.describe FileIndexPoint, type: :model do
  context 'properties' do
    subject { create :file_index_point }
    it 'should include attributes' do
      expect(subject).to have_attribute(:title)
      expect(subject).to have_attribute(:start_time)
      expect(subject).to have_attribute(:end_time)
      expect(subject).to have_attribute(:duration)
      expect(subject).to have_attribute(:synopsis)
      expect(subject).to have_attribute(:partial_script)
      expect(subject).to have_attribute(:gps_latitude)
      expect(subject).to have_attribute(:gps_longitude)
      expect(subject).to have_attribute(:gps_zoom)
      expect(subject).to have_attribute(:gps_description)
      expect(subject).to have_attribute(:hyperlink)
      expect(subject).to have_attribute(:hyperlink_description)
      expect(subject).to have_attribute(:subjects)
      expect(subject).to have_attribute(:keywords)
    end
  end

end
