require "rails_helper"

RSpec.describe FileTranscriptPoint, type: :model do
  context 'properties' do
    subject { create :file_transcript_point }
    it 'should include attributes' do
      expect(subject).to have_attribute(:title)
      expect(subject).to have_attribute(:start_time)
      expect(subject).to have_attribute(:end_time)
      expect(subject).to have_attribute(:duration)
      expect(subject).to have_attribute(:text)
      expect(subject).to have_attribute(:speaker)
      expect(subject).to have_attribute(:writing_direction)
    end
  end

end
