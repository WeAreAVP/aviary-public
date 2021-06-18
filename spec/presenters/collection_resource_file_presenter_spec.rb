require "rails_helper"

RSpec.describe CollectionResourceFilePresenter, type: :Presenter do
  let(:collection_resource_file) { build :collection_resource_file, attributes_for(:collection_resource_file, :check_ffmpeg) }
  let(:file_transcript) { build :file_transcript, attributes_for(:file_transcript, :use_webvtt) }
  let(:collection_resource_file_embed) { create :collection_resource_file, attributes_for(:collection_resource_file, :check_embed) }
  let(:template) { ActionController::Base.new.view_context }
  let(:presenter) { CollectionResourceFilePresenter.new(collection_resource_file_embed, template) }
  let(:presenter1) { CollectionResourceFilePresenter.new(collection_resource_file, template) }
  describe '#CollectionResourceFilePresenter' do
    context 'Check Presenter Methods' do
      it 'should provide media_url from the embed code' do
        expect(presenter.media_url).to include('zzfCVBSsvqA')
      end
      it 'should provide media_type of the embed code' do
        expect(presenter.media_type).to include('youtube')
      end
      it 'should provide media_url of mp4 resource file' do
        expect(presenter1.media_url).to include('small.mp4')
      end
      it 'should provide media_type of mp4 resource file' do
        expect(presenter1.media_type).to include('video')
      end
      # it 'should provide the tracks for the close caption' do
      #   file_transcript.collection_resource_file = collection_resource_file_embed
      #   file_transcript.save
      #   expect(presenter.tracks).to be_truthy
      # end
    end
  end
end