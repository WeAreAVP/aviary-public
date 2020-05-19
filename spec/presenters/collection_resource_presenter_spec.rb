require "rails_helper"

RSpec.describe CollectionResourcePresenter, type: :Presenter do
  let!(:collection_resource_file) { build :collection_resource_file, attributes_for(:collection_resource_file, :check_ffmpeg) }
  let(:file_transcript) { build :file_transcript, attributes_for(:file_transcript, :use_webvtt) }
  let(:collection_resource_file_embed) { create :collection_resource_file, attributes_for(:collection_resource_file, :check_embed) }
  let(:template) { ActionController::Base.new.view_context }
  let(:presenter) { CollectionResourcePresenter.new(collection_resource_file.collection_resource, template) }
  before do
    allow(presenter).to receive(:collection_collection_resource_path).and_return(true)
    allow(presenter).to receive(:collection_collection_resource_add_resource_file_path).and_return(true)
    allow(presenter).to receive(:edit_collection_collection_resource_path).and_return(true)
    allow(presenter).to receive(:add_breadcrumb).and_return(true)
  end
  describe '#CollectionResourcePresenter' do
    context 'Check Presenter Methods' do
      it 'breadcrumb_manager(type, collection_resource, collection)' do
        presenter.breadcrumb_manager('edit', collection_resource_file.collection_resource, collection_resource_file.collection_resource.collection)
      end
      
      it 'breadcrumb_manager(type, collection_resource, collection)' do
        presenter.breadcrumb_manager('manage_file', collection_resource_file.collection_resource, collection_resource_file.collection_resource.collection)
      end
    end
  end
end