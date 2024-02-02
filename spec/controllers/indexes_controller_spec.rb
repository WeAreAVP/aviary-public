require 'rails_helper'
RSpec.describe IndexesController, type: :controller do
  include ApplicationHelper
  let(:file_index) { create(:file_index) }
  let(:file_index_point) { create :file_index_point, file_index: file_index }

  before do
    request[:subdomain] = file_index.collection_resource_file.collection_resource.collection.organization.url
    allow(controller).to receive(:current_organization).and_return(file_index.collection_resource_file.collection_resource.collection.organization)
    allow(controller).to receive(:current_user).and_return(file_index.collection_resource_file.collection_resource.collection.organization.user)
    sign_in(file_index.collection_resource_file.collection_resource.collection.organization.user)
    allow(controller).to receive(:authenticate_user!).and_return(true)
  end
  describe "POST Create" do
    it "has a 200 status code with no error on index create" do
      post :create, params: { resource_file_id: file_index.collection_resource_file.id,
                              file_index: { title: file_index.title, associated_file: fixture_file_upload("#{Rails.root}/spec/fixtures/valid_sample_xml.xml", 'application/xml'),
                                            is_public: file_index.is_public, language: file_index.language } },
           format: :json
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)[0]['errors']).to be_empty
    end
    it "has a 200 status code with no error on index delete and then create" do
      post :create, params: { resource_file_id: file_index.collection_resource_file.id, file_index_id: file_index.id,
                              file_index: { title: file_index.title, associated_file: fixture_file_upload("#{Rails.root}/spec/fixtures/valid_sample_xml.xml", 'application/xml'),
                                            language: file_index.language, is_public: file_index.is_public } },
           format: :json
      expect(JSON.parse(response.body)[0]['errors']).to be_empty
      expect(response.status).to eq(200)
    end
    it "has a 200 status code with error" do
      post :create, params: { resource_file_id: file_index.collection_resource_file.id,
                              file_index: { title: '', associated_file: fixture_file_upload("#{Rails.root}/spec/fixtures/valid_sample_xml.xml", 'application/xml'),
                                            is_public: file_index.is_public, language: file_index.language } },
           format: :json
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)[0]['errors']).not_to be_empty
    end
  end
  describe "PATCH Index Point Update" do
    it "has a 302 status code with no error on file index point update" do
      updated_title = 'This is a new Title'
      post :update_index, params: { resource_file_id: file_index.collection_resource_file.id, file_index_id: file_index.id, file_index_point_id: file_index_point.id,
                                    file_index_point: { start_time: file_index_point.start_time, id: file_index_point.id, title: updated_title,
                                      synopsis: file_index_point.synopsis&.split('|||')&.map { |term| {vocabulary: term&.split(':::')[1] , value: term&.split(':::')[0]} },
                                      partial_script: file_index_point.synopsis&.split('|||')&.map { |term| {vocabulary: term&.split(':::')[1] , value: term&.split(':::')[0]} },
                                      keywords: file_index_point.keywords, subjects: file_index_point.subjects, gps_latitude: JSON.parse(file_index_point.gps_latitude),
                                      gps_description: JSON.parse(file_index_point.gps_description), zoom: JSON.parse(file_index_point.gps_zoom),
                                      hyperlink: JSON.parse(file_index_point.hyperlink), hyperlink_description: JSON.parse(file_index_point.hyperlink_description)
                                    }
                                  },
            format: :html

      expect(response.status).to eq(302)
      expect(FileIndexPoint.find(file_index_point.id).title).to eq(updated_title)
    end

    it "has a 422 status code with error on file index point update with empty title" do
      updated_title = 'This is a new Title'
      post :update_index, params: { resource_file_id: file_index.collection_resource_file.id, file_index_id: file_index.id, file_index_point_id: file_index_point.id,
                                    file_index_point: { start_time: file_index_point.start_time, id: file_index_point.id, title: nil,
                                      synopsis: file_index_point.synopsis&.split('|||')&.map { |term| {vocabulary: term&.split(':::')[1] , value: term&.split(':::')[0]} },
                                      partial_script: file_index_point.synopsis&.split('|||')&.map { |term| {vocabulary: term&.split(':::')[1] , value: term&.split(':::')[0]} },
                                      keywords: file_index_point.keywords, subjects: file_index_point.subjects, gps_latitude: JSON.parse(file_index_point.gps_latitude),
                                      gps_description: JSON.parse(file_index_point.gps_description), zoom: JSON.parse(file_index_point.gps_zoom),
                                      hyperlink: JSON.parse(file_index_point.hyperlink), hyperlink_description: JSON.parse(file_index_point.hyperlink_description)
                                    }
                                  },
            format: :json

      expect(response.status).to eq(422)
      expect(JSON.parse(response.body)['title']).not_to eq('can\'t be blank')
    end
  end

  describe 'File Index VTT Import/Export Functionality Test' do
    it 'successfully imports and exports VTT file' do
      vtt_file_path = "#{Rails.root}/spec/fixtures/valid_vtt_index_with_metadata_for_import.webvtt"
      post_params = { resource_file_id: file_index.collection_resource_file.id,
                      file_index: {
                        title: file_index.title,
                        associated_file: fixture_file_upload(vtt_file_path,'text/vtt'),
                        is_public: file_index.is_public,
                        language: file_index.language
                      }
                    }

      post :create, params: post_params, format: :json

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)[0]['errors']).to be_empty

      file_index = FileIndex.last
      assert_file_index_points(file_index, 3)

      assert_file_index_point(
        file_index.file_index_points.first, 'TItle', 0.0, 0.6433e4, 'Partial Script',
        ['12.345','543.21'], ['21.543','345.12'], ['17','17'], ['Point 1','Point 2'],
        ['www.link1.com','www.link2.com'], ['Link 1','Link 2'], 'Subject;Keyword',
        'Keywords;Subjects', 0, nil, nil, nil, nil, nil,
        'Synopsis:::First Term|||Second Synopsis:::Second Term|||Third Synopsis:::Third Term',
        [{ lat: '12.345', long: '21.543', zoom: '17', description: 'Point 1' },
         { lat: '543.21', long: '345.12', zoom: '17', description: 'Point 2' }],
        [{ hyperlink: 'www.link1.com', description: 'Link 1' },
         { hyperlink: 'www.link2.com', description: 'Link 2' }]
      )

      assert_file_index_point(
        file_index.file_index_points.second, 'Exporter', 0.6433e4, 0.72e4, '', [], [],
        ['17'], [], [], [], '', '', 0, nil, nil, nil, nil, nil, 'Synopsis', [], []
      )

      assert_file_index_point(
        file_index.file_index_points.third, 'Introduction', 0.72e4, 0.8536e4,
        'There were UN observers', ['11.211'], ['21.121'], ['17'],
        ['Random point on the map'], ['https://hyperlink.com'], ['A random hyperlink'],
        'Introduction', 'Jordan B. Peterson', 0, nil, nil, nil, nil, nil,
        'PBD introduces a Jordan B Peterson',
        [{ lat: '11.211', long: '21.121', zoom: '17', description: 'Random point on the map' }],
        [{ hyperlink: 'https://hyperlink.com', description: 'A random hyperlink' }]
      )
    end

  describe "PATCH Sort" do
    it "has a 200 status code with no error" do
      post :sort, params: { resource_file_id: file_index.collection_resource_file.id,
                            sort_list: [file_index.id] },
           format: :json
      expect(response.status).to eq(200)
    end
  end
  describe "Delete destroy" do
    it "has a 200 status code with no error" do
      delete :destroy, params: { id: file_index.id }
      expect(response.status).to eq(302)
    end
  end
end
