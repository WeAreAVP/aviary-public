require "rails_helper"

RSpec.describe FileTranscript, type: :model do
  let(:file_transcript_invalid) { build :file_transcript, attributes_for(:file_transcript, :invalid) }
  let(:file_transcript_ohms_missing) { build :file_transcript, attributes_for(:file_transcript, :use_ohms_missing) }
  let(:file_transcript_webvtt_missing) { build :file_transcript, attributes_for(:file_transcript, :use_webvtt_missing) }
  context 'properties' do
    subject { create :file_transcript }
    it 'should include attributes' do
      expect(subject).to have_attribute(:title)
      expect(subject).to have_attribute(:language)
      expect(subject).to have_attribute(:is_public)
      expect(subject).to have_attribute(:sort_order)
      expect(subject).to have_attribute(:sort_order)
    end
  end
  it 'should pass the file xml validation for invalid xml because of relaxing rules' do
    file_transcript_invalid.valid?
    expect(file_transcript_invalid.errors[:associated_file].size).to eq(0)
    expect(file_transcript_invalid.errors[:title].size).to eq(1)
  end

  it 'should fail the file ohms validation because of missing transcript' do
    file_transcript_ohms_missing.valid?
    expect(file_transcript_ohms_missing.errors[:associated_file].size).to eq(1)
  end

end
