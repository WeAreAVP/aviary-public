require "rails_helper"

RSpec.describe Aviary::IndexTranscriptManager, type: :service do
  let(:file_index) { create :file_index }
  let(:file_index_alt) { create :file_index, attributes_for(:file_index, :use_ohms_index_alt) }
  let(:file_index_webvtt) { create :file_index, attributes_for(:file_index, :use_webvtt) }
  let(:file_transcript) { create :file_transcript }
  let(:file_transcript_webvtt) { create :file_transcript, attributes_for(:file_transcript, :use_webvtt) }
  let(:file_transcript_txt_format) { create :file_transcript, attributes_for(:file_transcript, :use_simple_timestamp_txt) }
  let(:file_transcript_txt) { create :file_transcript, attributes_for(:file_transcript, :use_simple_txt) }
  context 'check the Index Manager methods with OHMS XML' do
    subject { Aviary::IndexTranscriptManager::IndexManager.new.process(file_index) }
    it 'should successfully process the file and return true' do
      expect(subject).to be_truthy
    end
  end
  context 'check the Index Manager methods of OHMS XML with alt index' do
    subject { Aviary::IndexTranscriptManager::IndexManager.new.process(file_index_alt) }
    it 'should successfully process the file and return true' do
      expect(subject).to be_truthy
    end
  end
  context 'check the Index Manager methods with WebVTT' do
    subject { Aviary::IndexTranscriptManager::IndexManager.new.process(file_index_webvtt) }
    it 'should successfully process the file and return true' do
      expect(subject).to be_truthy
    end
  end
  context 'check the Transcript Manager methods with OHMS XML' do
    subject { Aviary::IndexTranscriptManager::TranscriptManager.new.process(file_transcript) }
    it 'should successfully process the file and return true' do
      expect(subject).to be_truthy
    end
  end
  context 'check the Transcript Manager methods with WebVTT' do
    subject { Aviary::IndexTranscriptManager::TranscriptManager.new.process(file_transcript_webvtt) }
    it 'should successfully process the file and return true' do
      expect(subject).to be_truthy
    end
  end
  context 'check the Transcript Manager methods with Simple text with timestamp' do
    subject { Aviary::IndexTranscriptManager::TranscriptManager.new.process(file_transcript_txt_format) }
    it 'should successfully process the file and return true' do
      expect(subject).to be_truthy
    end
  end
  context 'check the Transcript Manager methods with Simple text without timestamp' do
    subject { Aviary::IndexTranscriptManager::TranscriptManager.new.process(file_transcript_txt) }
    it 'should successfully process the file and return true' do
      expect(subject).to be_truthy
    end
  end
end