require "rails_helper"

RSpec.describe FileTranscriptPointPresenter, type: :Presenter do
  let(:file_transcript_point) { create :file_transcript_point }
  let(:file_transcript_point_empty_speaker) { create :file_transcript_point, attributes_for(:file_transcript_point, :empty_speaker) }
  let(:template) { ActionController::Base.new.view_context }
  let(:presenter) { FileTranscriptPointPresenter.new(file_transcript_point, template) }
  let(:presenter_alt) { FileTranscriptPointPresenter.new(file_transcript_point_empty_speaker, template) }
  describe 'FileTranscriptPointPresenter ' do
    context 'Check Presenter Methods' do
      it 'should provide time in format' do
        expect(presenter.display_time).to eq('00:00:06')
      end
      it 'should provide title with timecode' do
        expect(presenter.title_with_timecode).to be_truthy
      end
      it 'should provide speaker with text' do
        expect(presenter.speaker_with_text).to be_truthy
        expect(presenter_alt.speaker_with_text).to be_truthy
      end
    end
  end
end
