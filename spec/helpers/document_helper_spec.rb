require 'rails_helper'

RSpec.describe DocumentHelper, type: :helper do
  let(:document) {{'description_title_search_texts_occurrence_testing' => '10'}}
  describe '#description_search_fields' do
    it 'should return array' do
      expect(helper.description_search_fields).to be_a_kind_of(Array)
      expect(helper.index_search_fields).to be_a_kind_of(Array)
      expect(helper.description_simple_fields).to be_a_kind_of(Array)
      expect(helper.transcript_search_fields).to be_a_kind_of(Array)
      expect(helper.other_fields).to be_a_kind_of(Array)
    end
  end

  describe '#solr_to_aviary_description' do
    it 'should return array' do
      expect(helper.tracking_term_separator({'keywords' => 'Testing OR 10'})).to eq(['Testing ', ' 10'])
    end
  end


end
