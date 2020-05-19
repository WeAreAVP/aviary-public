require 'rails_helper'
RSpec.describe TranscriptsController, type: :controller do
  let(:file_transcript) { create(:file_transcript) }
  let(:file_transcript_webvtt) { create :file_transcript, attributes_for(:file_transcript, :use_webvtt) }
  before do
    request[:subdomain] = file_transcript.collection_resource_file.collection_resource.collection.organization.url
    allow(controller).to receive(:current_organization).and_return(file_transcript.collection_resource_file.collection_resource.collection.organization)
    allow(controller).to receive(:current_user).and_return(file_transcript.collection_resource_file.collection_resource.collection.organization.user)
    sign_in(file_transcript.collection_resource_file.collection_resource.collection.organization.user)
    allow(controller).to receive(:authenticate_user!).and_return(true)
  end
  describe "POST Create" do
    it "has a 200 status code with no error on transcript create" do
      post :create, params: { resource_file_id: file_transcript.collection_resource_file.id,
                              file_transcript: { title: file_transcript.title, associated_file: fixture_file_upload("#{Rails.root}/spec/fixtures/valid_sample_xml.xml", 'application/xml'),
                                                 is_public: file_transcript.is_public, language: file_transcript.language } },
           format: :json
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)[0]['errors']).to be_empty
    end
    it "has a 200 status code with no error on transcript create with alt" do
      post :create, params: { resource_file_id: file_transcript.collection_resource_file.id,
                              file_transcript: { title: file_transcript.title, associated_file: fixture_file_upload("#{Rails.root}/spec/fixtures/valid_transcript_with_alt.xml", 'application/xml'),
                                                 is_public: file_transcript.is_public, language: file_transcript.language } },
           format: :json
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)[0]['errors']).to be_empty
    end
    it "has a 200 status code with error" do
      post :create, params: { resource_file_id: file_transcript.collection_resource_file.id,
                              file_transcript: { title: '', associated_file: fixture_file_upload("#{Rails.root}/spec/fixtures/valid_sample_xml.xml", 'application/xml'),
                                                 is_public: file_transcript.is_public, language: file_transcript.language } },
           format: :json
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)[0]['errors']).not_to be_empty
    end
    it "has a 200 status code with error due to invalid data in the xml" do
      post :create, params: { resource_file_id: file_transcript.collection_resource_file.id,
                              file_transcript: { title: file_transcript.title, associated_file: fixture_file_upload("#{Rails.root}/spec/fixtures/invalid_transcript.xml", 'application/xml'),
                                                 is_public: file_transcript.is_public, language: file_transcript.language } },
           format: :json
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)[0]['errors']).not_to be_empty
    end
    it "has a 200 status code with no error on transcript delete and then create" do
      post :create, params: { resource_file_id: file_transcript.collection_resource_file.id, file_transcript_id: file_transcript.id,
                              file_transcript: { associated_file: fixture_file_upload("#{Rails.root}/spec/fixtures/valid_sample_xml.xml", 'application/xml'),
                                                 is_public: file_transcript.is_public } },
           format: :json
      expect(JSON.parse(response.body)[0]['errors']).to be_empty
      expect(response.status).to eq(200)
    end
    describe "PATCH Sort" do
      it "has a 200 status code with no error" do
        post :sort, params: { resource_file_id: file_transcript.collection_resource_file.id,
                              sort_list: [file_transcript.id] },
             format: :json
        expect(response.status).to eq(200)
      end
    end
  end
  describe "Delete destroy" do
    it "has a 200 status code with no error" do
      delete :destroy, params: { id: file_transcript.id }
      expect(response.status).to eq(302)
    end
  end
  describe "Get Export" do
    it "has a 200 status code with binary txt file" do
      file_points = create(:file_transcript_point)
      get :export, params: { id: file_points.file_transcript.id, type: 'txt' }
      expect(controller.headers['Content-Transfer-Encoding']).to eq('binary')
    end
    it "has a 200 status code with binary webvtt file" do
      get :export, params: { id: file_transcript_webvtt.id, type: 'webvtt' }
      expect(controller.headers['Content-Transfer-Encoding']).to eq('binary')
    end
    it "has a 200 status code with binary json file" do
      get :export, params: { id: file_transcript_webvtt.id, type: 'json' }
      expect(controller.headers['Content-Transfer-Encoding']).to eq('binary')
    end
    it "has a 302 redirect due to invalid type" do
      get :export, params: { id: file_transcript_webvtt.id, type: 'text' }
      expect(response.status).to eq(302)
    end
    it "has a 302 redirect due to record not found" do
      get :export, params: { id: 312, type: 'txt' }
      expect(response.status).to eq(302)
    end

  end


end
