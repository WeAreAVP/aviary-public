require 'rails_helper'
RSpec.describe CatalogController, type: :controller do
  include ApplicationHelper

  let!(:collection) { create(:collection, title: 'testing collection') }
  let!(:collection_resource) { create(:collection_resource, title: 'dora and salo holocaust testimony testing', collection: collection) }
  let!(:collection_resource_2) { create(:collection_resource, title: 'dora holocaust testimony', collection: collection) }
  let!(:collection_resource_3) { create(:collection_resource, title: 'new resource 1', collection: collection) }
  let!(:collection_resource_4) { create(:collection_resource, title: 'new resource 2', collection: collection) }
  let!(:collection_resource_file_vimeo) { build :collection_resource_file, attributes_for(:collection_resource_file, :check_vimeo) }
  let!(:collection_resource_file) { build :collection_resource_file, collection_resource: collection_resource }

  describe "Get Search" do
    before (:each) do
      collection_resource_2.reindex_collection_resource
      collection_resource_3.reindex_collection_resource
      collection_resource_4.reindex_collection_resource
    end

    it "no keyword search" do
      get :index, params: { utf8: '✓', update_advance_search: 'update_advance_search', search_type: 'simple', search_field: 'advanced', commit: 'Search', type_of_field_selector_single: 'keywords',
                            keywords: [''], title_text: [''], resource_description: [''], indexes: [''], transcript: [''], op: [''], type_of_search: ['simple'] }, format: :json
      expect(response.status).to eq(200)
      expect(assigns(:document_list).size).to be >= 4
    end

    it "keyword search dora+AND+salo" do
      get :index, params: { utf8: '✓', update_advance_search: 'update_advance_search', search_type: 'simple', search_field: 'advanced', commit: 'Search', type_of_field_selector_single: 'keywords',
                            keywords: ['dora AND salo'], title_text: [''], resource_description: [''], indexes: [''], transcript: [''], op: [''], type_of_search: ['simple'] }, format: :json
      expect(response.status).to eq(200)
      expect(assigns(:document_list).size).to eq(1)
    end

    it "keyword search dora OR salo" do
      get :index, params: { utf8: '✓', update_advance_search: 'update_advance_search', search_type: 'simple', search_field: 'advanced', commit: 'Search', type_of_field_selector_single: 'keywords',
                            keywords: ['dora OR salo'], title_text: [''], resource_description: [''], indexes: [''], transcript: [''], op: [''], type_of_search: ['simple'] }, format: :json
      expect(response.status).to eq(200)
      expect(assigns(:document_list).size).to eq(2)
    end

    it "keyword search dora NOT salo" do
      get :index, params: { utf8: '✓', update_advance_search: 'update_advance_search', search_type: 'simple', search_field: 'advanced', commit: 'Search', type_of_field_selector_single: 'keywords',
                            keywords: ['dora NOT salo'], title_text: [''], resource_description: [''], indexes: [''], transcript: [''], op: [''], type_of_search: ['simple'] }, format: :json
      expect(response.status).to eq(200)
      expect(assigns(:document_list).size).to eq(1)
    end

    it 'keyword search "dora and salo"' do
      get :index, params: { utf8: '✓', update_advance_search: 'update_advance_search', search_type: 'simple', search_field: 'advanced', commit: 'Search', type_of_field_selector_single: 'keywords',
                            keywords: [''], title_text: ['dora AND salo'], resource_description: [''], indexes: [''], transcript: [''], op: [''], type_of_search: ['simple'] }, format: :json
      expect(response.status).to eq(200)
      expect(assigns(:document_list).size).to eq(1)
    end

    it 'keyword search dora AND testimony NOT salo' do
      get :index, params: { utf8: '✓', update_advance_search: 'update_advance_search', search_type: 'simple', search_field: 'advanced', commit: 'Search', type_of_field_selector_single: 'keywords',
                            keywords: ['dora AND testimony NOT salo'], title_text: [''], resource_description: [''], indexes: [''], transcript: [''], op: [''], type_of_search: ['simple'] }, format: :json
      expect(response.status).to eq(200)
      expect(assigns(:document_list).size).to eq(1)
    end

    it 'keyword search new AND resource NOT "new resource 1" ' do
      get :index, params: { utf8: '✓', update_advance_search: 'update_advance_search', search_type: 'simple', search_field: 'advanced', commit: 'Search', type_of_field_selector_single: 'keywords',
                            keywords: ['new AND resource NOT new resource 1'], title_text: [''], resource_description: [''], indexes: [''], transcript: [''], op: [''], type_of_search: ['simple'] }, format: :json
      expect(response.status).to eq(200)
      expect(assigns(:document_list).size).to eq(1)
    end

    it 'keyword search "new resource 1"  OR "new resource 2" ' do
      get :index, params: { utf8: '✓', update_advance_search: 'update_advance_search', search_type: 'simple', search_field: 'advanced', commit: 'Search', type_of_field_selector_single: 'keywords',
                            keywords: ['new resource 1  OR new resource 2'], title_text: [''], resource_description: [''], indexes: [''], transcript: [''], op: [''], type_of_search: ['simple'] }, format: :json
      expect(response.status).to eq(200)
      expect(assigns(:document_list).size).to eq(2)
    end

    it 'keyword search (dora AND salo) OR (new AND resource )' do
      get :index, params: { utf8: '✓', update_advance_search: 'update_advance_search', search_type: 'simple', search_field: 'advanced', commit: 'Search', type_of_field_selector_single: 'keywords',
                            keywords: ['(dora AND salo) OR (new AND resource) '], title_text: [''], resource_description: [''], indexes: [''], transcript: [''], op: [''], type_of_search: ['simple'] }, format: :json
      expect(response.status).to eq(200)
      expect(assigns(:document_list).size).to eq(3)
    end

    it 'keyword search dora OR salo OR new AND resource AND "new resource 1" ' do
      get :index, params: { utf8: '✓', update_advance_search: 'update_advance_search', search_type: 'simple', search_field: 'advanced', commit: 'Search', type_of_field_selector_single: 'keywords',
                            keywords: ['dora OR salo OR new AND resource AND new resource 1 '], title_text: [''], resource_description: [''], indexes: [''], transcript: [''], op: [''], type_of_search: ['simple'] }, format: :json

      expect(response.status).to eq(200)
      expect(assigns(:document_list).size).to eq(1)
    end

    it 'keyword search hvt.1021.232 AND "dfgh ghjk" AND dfgh AND "ghjk"' do
      get :index, params: { utf8: '✓', update_advance_search: 'update_advance_search', search_type: 'simple', search_field: 'advanced', commit: 'Search', type_of_field_selector_single: 'keywords',
                            keywords: ['hvt.1021.232 AND dfgh ghjk AND dfgh AND ghjk AND *ing'], title_text: [''], resource_description: [''], indexes: [''], transcript: [''], op: [''], type_of_search: ['simple'] }, format: :json
      expect(response.status).to eq(200)
      expect(assigns(:document_list).size).to eq(0)
    end

    it "Check if search is working " do
      get :index, params: { utf8: '✓', search_field: 'keywords', q: '' }, format: :json
      expect(response.status).to eq(200)
    end

    it 'Advance Search' do
      get :index, params: { utf8: '✓', update_advance_search: 'update_advance_search', search_type: 'advance', keywords: ['dora', 'salo', 'testimony'], title_text: ['', '', ''], resource_description: ['', '', ''],
                            indexes: ['', '', ''], transcript: ['', '', ''], op: ['', 'AND', 'AND'], type_of_search: ['simple', 'simple', 'simple'], sort: 'score asc', search_field: 'advanced', commit: 'Search' }, format: :json
      expect(response.status).to eq(200)
      expect(assigns(:document_list).size).to eq(1)
    end

    it "title search dora AND salo" do
      get :index, params: { utf8: '✓', update_advance_search: 'update_advance_search', search_type: 'simple', search_field: 'advanced', commit: 'Search', type_of_field_selector_single: 'title_text',
                            keywords: [''], title_text: ['dora AND salo'], resource_description: [''], indexes: [''], transcript: [''], op: [''], type_of_search: ['simple'] }, format: :json
      expect(response.status).to eq(200)
      expect(assigns(:document_list).size).to eq(1)
    end
    it "resource Description search dora AND salo" do
      get :index, params: { utf8: '✓', update_advance_search: 'update_advance_search', search_type: 'simple', search_field: 'advanced', commit: 'Search', type_of_field_selector_single: 'resource_description',
                            keywords: [''], title_text: [''], resource_description: ['hvt.1021.232'], indexes: [''], transcript: [''], op: [''], type_of_search: ['simple'] }, format: :json
      expect(response.status).to eq(200)
      expect(assigns(:document_list).size).to eq(0)
    end

    it "collection title testing" do
      get :index, params: { utf8: '✓', update_advance_search: 'update_advance_search', search_type: 'simple', search_field: 'advanced', commit: 'Search', type_of_field_selector_single: 'resource_description',
                            keywords: [''], title_text: [''], collection_title: ['testing'], resource_description: [''], indexes: [''], transcript: [''], op: [''], type_of_search: ['simple'] }, format: :json
      expect(response.status).to eq(200)
      expect(assigns(:document_list).size).to eq(4)
    end

    it "indexes testing" do
      get :index, params: { utf8: '✓', update_advance_search: 'update_advance_search', search_type: 'simple', search_field: 'advanced', commit: 'Search', type_of_field_selector_single: 'resource_description',
                            keywords: [''], title_text: [''], collection_title: [''], resource_description: [''], indexes: ['testing'], transcript: [''], op: [''], type_of_search: ['simple'] }, format: :json
      expect(response.status).to eq(200)
      expect(assigns(:document_list).size).to eq(0)
    end

    it "resource Description search dora AND salo" do
      SearchBuilder::search_field_labels
      get :index, params: { utf8: '✓', update_advance_search: 'update_advance_search', search_type: 'simple', search_field: 'advanced', commit: 'Search', type_of_field_selector_single: 'resource_description',
                            keywords: [''], title_text: [''], collection_title: [''], resource_description: [''], indexes: [''], transcript: ['testing'], op: [''], type_of_search: ['simple'] }, format: :json
      expect(response.status).to eq(200)
      expect(assigns(:document_list).size).to eq(0)
    end

  end
end
