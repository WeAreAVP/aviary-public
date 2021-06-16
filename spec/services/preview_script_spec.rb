require "rails_helper"
RSpec.describe PreviewScript, type: :service do
  let!(:user) {create(:user)}
  let!(:organization) {create(:organization, name: 'testing org', user_id: user.id)}
  let!(:collection) {create(:collection, organization: organization)}
  let!(:collection_one) {create(:collection, organization: organization)}
  let!(:collection_resource) {create(:collection_resource, title: 'testing resource', collection: collection)}

  let!(:params) { {'collection_title' => "hellow collection", 'tombstone' => ["title"],
                   'visible' => ["agent"],  'sort_order' =>  { 'sort_data' => [] }, 'new_custom_value' => {'new_custom_field' => "hellow_test"}
  } }
  describe '#data_hash' do

    context 'when resource is present' do
      subject { PreviewScript.new(collection).data_hash(collection_resource, nil) }
      it 'it return resource name in hash' do
        expect(subject["resource_title"]).to eq(collection_resource.title)
      end

      it 'it return collection name in hash' do
        expect(subject["collection_title"]).to eq(collection.title)
      end

      it 'it return organization name in hash' do
        expect(subject["organization_title"]).to eq(organization.name)
      end

      it 'it return collection name in hash' do
        expect(subject).not_to be_nil
      end

      it 'it return collection name in hash' do
        expect(subject["collection_title"]).to include("title")
      end
    end

    context 'when resource is not present' do
      subject { PreviewScript.new(collection).data_hash(nil,  nil) }

      it 'it return resource name in hash' do
        expect(subject["resource_title"]).to eq("This is the Resource Title")
      end
    end
  end

  describe '#update_data_hash' do
    subject { PreviewScript.new(collection, params).update_data_hash(PreviewScript.new(collection).data_hash(collection_resource, nil)) }
    context 'when resource is present' do

      it 'it return resource name in hash' do
        expect(subject['fields']["resource_title"]).to eq(collection_resource.title)
      end

      it 'it update tombstone value' do
        expect(subject["fields"].present? && subject["fields"][1].present? && subject["fields"][1]["title"].present? && subject["fields"][1]["title"].first["is_tombstone"]).to be_in([true, false])
      end

      it 'it update visible value' do
        expect(subject["fields"].present? && subject["fields"][1].present? && subject["fields"][1]["title"].present? && subject["fields"][1]["title"].first["is_visible"]).to be_in([true, false])
      end
    end
  end

  describe '#preview_hash_switch' do

    context 'when system value is title' do

      subject { PreviewScript.new(collection, params).preview_hash_switch('title') }

      it 'will return title string' do
        expect(subject.first).to eq('This is the Resource title')
      end
    end

    context 'when system value is rights_statement' do

      subject { PreviewScript.new(collection, params).preview_hash_switch('rights_statement') }

      it 'will return rights_statement string' do
        expect(subject.first).to eq('This is a rights statement')
      end
    end

    context 'when system value is publisher' do

      subject { PreviewScript.new(collection, params).preview_hash_switch('publisher') }

      it 'will return publisher string' do
        expect(subject.first).to eq('The Publishing Entity')
      end
    end
  end
end