require "rails_helper"

RSpec.describe Collection, type: :model do
  include Aviary::ResourceFileManagement
  let!(:user) {create(:user)}
  let!(:organization) {create(:organization, name: 'testing org', user_id: user.id)}
  let!(:collection) {create(:collection, organization: organization)}
  let!(:collection_one) {create(:collection, organization: organization)}
  let!(:collection_resource) {create(:collection_resource, title: 'testing resource', collection: collection)}


  context 'properties' do
    fields_to_check =%i[title about image_file_name image_content_type image_file_size image_updated_at is_public is_featured organization_id created_at updated_at]
    fields_to_check.each do |value|
      it "should include #{value} attributes" do
        expect(collection).to have_attribute(value)
      end
    end
  end

  describe '#collection ' do
    context 'Connected fields with collection ' do
      it 'Check if returns fields related to collection' do
        org_field = Aviary::FieldManagement::OrganizationFieldManager.new.organization_field_settings(collection.organization, nil, 'collection_fields', 'sort_order')
        expect(org_field.length).to eq(7)
      end
    end
    context 'collection' do
      it 'Check if correct Organization' do
        expect(collection.organization.name).to eq('testing org')
      end
    end
    context 'collection' do
      it 'Check if correct Resource' do
        expect(collection.collection_resources.first.title).to eq('testing resource')
      end
    end
    context 'collection' do
      it 'Check if collection field exists' do
        org_field = Aviary::FieldManagement::OrganizationFieldManager.new.organization_field_settings(collection.organization, nil, 'collection_fields', 'sort_order')
        expect(org_field.length).to eq(7)
      end
    end

  end
end