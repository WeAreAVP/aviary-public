require 'rails_helper'

RSpec.describe SearchHelper, type: :helper do
  let(:collection) { create(:collection) }
  let(:arguments) {[:description_agent_sms, 1, {description_agent_sms: ['vocab 1:: val1 ', 'vocab 2::val 2 ']}]}
  let(:arguments_1) {[:description_agent_sms, 1, {description_agent_sms: ['testing asdasd', 't']}]}
  let(:document) {{"collection_id_is" => collection.id, "id_is" => 1, "organization_id_is" => collection.organization.id}}

  describe '#Tombstone_display' do
    it 'should return array' do
      expect(helper.tombstone_display(arguments.first, arguments.second, arguments.third).length).to eq(3)
      expect(helper.tombstone_display(arguments_1.first, arguments_1.second, arguments_1.third).length).to eq(3)
    end
  end
  describe '#solr_to_aviary_description' do
    it 'should return array' do
      expect(helper.solr_to_aviary_description).to be_a_kind_of(Hash)
      expect(helper.solr_to_aviary_description(:description_title_sms)).to be_a_kind_of(String)
    end
  end
  describe '#document_detail_url render_collection_facet_value render_organization_facet_value' do
    it 'should return String' do
      expect(helper.document_detail_url(document, nil)).to be_a_kind_of(String)
      expect(helper.render_collection_facet_value(collection.id)).to be_a_kind_of(String)
      expect(helper.render_organization_facet_value(collection.organization.id)).to be_a_kind_of(String)
    end
  end


  describe '#avairy_to_solr_description' do
    it 'should return related Classes' do
      expect(helper.avairy_to_solr_description).to be_a_kind_of(Hash)
      expect(helper.avairy_to_solr_description('title')).to be_a_kind_of(Symbol)
    end
  end
end
