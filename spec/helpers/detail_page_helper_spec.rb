require 'rails_helper'


RSpec.describe DetailPageHelper, type: :helper do
  let(:file_index_point) { create(:file_index_point) }
  let(:file_transcript_point) { create(:file_transcript_point) }
  let!(:user) { create(:user) }
  let!(:organization) { create(:organization, name: 'testing org', user_id: user.id) }
  let!(:collection) { create(:collection, title: 'testing collection', organization: organization) }
  let!(:collection_resource) { create(:collection_resource, title: 'testing resource', collection: collection) }

  describe 'validate DetailPageHelper' do
    it 'validate count_occurrence' do
      tester = helper.count_occurrence(file_index_point, { "1f545a6d49bd6dc815ddd731d0c2a2ad" => "dora", "25b1902406e1629d19f07bba8b2f0cf0" => "salo" }, { 15 => {} }, 'index', false)
      expect(tester).to be_a_kind_of(Hash)
    end

    it 'validate count_occurrence' do
      tester = helper.count_occurrence(file_index_point, { "1f545a6d49bd6dc815ddd731d0c2a2ad" => "dora", "25b1902406e1629d19f07bba8b2f0cf0" => "salo" }, { 15 => {} }, 'index', true)
      expect(tester).to be_a_kind_of(Hash)
    end

    it 'validate count_occurrence' do
      tester = helper.count_occurrence(file_transcript_point, { "1f545a6d49bd6dc815ddd731d0c2a2ad" => "dora", "25b1902406e1629d19f07bba8b2f0cf0" => "salo" }, { 15 => {} }, 'transcript', false)
      expect(tester).to be_a_kind_of(Hash)
    end

    it 'validate count_occurrence' do
      tester = helper.count_occurrence(file_transcript_point, { "1f545a6d49bd6dc815ddd731d0c2a2ad" => "dora", "25b1902406e1629d19f07bba8b2f0cf0" => "salo" }, { 15 => {} }, 'transcript', true)
      expect(tester).to be_a_kind_of(Hash)
    end
  end
end
