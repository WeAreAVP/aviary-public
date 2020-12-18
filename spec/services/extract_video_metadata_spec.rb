require "rails_helper"

RSpec.describe Aviary::ExtractVideoMetadata, type: :service do
  let(:collection_resource_file_youtube) { build :collection_resource_file, attributes_for(:collection_resource_file, :check_embed) }
  let(:collection_resource_file_vimeo) { build :collection_resource_file, attributes_for(:collection_resource_file, :check_vimeo) }
  let(:collection_resource_file_soundcloud) { build :collection_resource_file, attributes_for(:collection_resource_file, :check_soundcloud) }
  let(:collection_resource_file_avalon) { build :collection_resource_file, attributes_for(:collection_resource_file, :check_avalon) }
  let(:collection_resource_file_avalon_443) { build :collection_resource_file, attributes_for(:collection_resource_file, :check_avalon_443) }
  context 'check the Extract Video Metadata Service and Youtube Class' do
    subject { Aviary::ExtractVideoMetadata::VideoEmbed.new(CollectionResourceFile.embed_type_name(collection_resource_file_youtube.embed_type), collection_resource_file_youtube.embed_code).metadata }
    it 'should successfully process the youtube embed and return its metadata' do
      expect(subject).to be_truthy
      expect(subject.size).to eq(5)
    end
  end
  #context 'check the Extract Video Metadata Service and Vimeo Class' do
  #  subject { Aviary::ExtractVideoMetadata::VideoEmbed.new(CollectionResourceFile.embed_type_name(collection_resource_file_vimeo.embed_type), collection_resource_file_vimeo.embed_code).metadata }
  #  it 'should successfully process the vimeo embed and return its metadata' do
  #    expect(subject).to be_truthy
  #    expect(subject.size).to eq(5)
  #  end
  #end
  context 'check the Extract Video Metadata Service and Soundcloud Class' do
    subject { Aviary::ExtractVideoMetadata::VideoEmbed.new(CollectionResourceFile.embed_type_name(collection_resource_file_soundcloud.embed_type), collection_resource_file_soundcloud.embed_code).metadata }
    it 'should successfully process the soundcloud embed and return its metadata' do
      expect(subject).to be_truthy
      expect(subject.size).to eq(5)
    end
  end
  context 'check the Extract Video Metadata Service and Avalon Class' do
    subject { Aviary::ExtractVideoMetadata::VideoEmbed.new(CollectionResourceFile.embed_type_name(collection_resource_file_avalon.embed_type), collection_resource_file_avalon.embed_code).metadata }
    it 'should successfully process the avalon embed and return its metadata' do
      expect(subject.size).to eq(5)
    end
  end
  context 'check the Extract Video Metadata Service and Avalon Class with 443 url' do
    subject { Aviary::ExtractVideoMetadata::VideoEmbed.new(CollectionResourceFile.embed_type_name(collection_resource_file_avalon_443.embed_type), collection_resource_file_avalon_443.embed_code).metadata }
    it 'should successfully process the avalon embed and return its metadata and replace 443 with https' do
      
      expect(subject).to be_truthy
      expect(subject.size).to eq(5)
    end
  end
end