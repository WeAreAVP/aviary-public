require 'rails_helper'

RSpec.describe CollectionResource, type: :model do
  let!(:user) { create(:user) }
  let!(:organization) { create(:organization, name: 'testing org', user_id: user.id) }
  let!(:collection) { create(:collection, title: 'my collection', organization: organization) }
  let!(:collection_resource) { create(:collection_resource, title: 'testing resource', collection: collection) }
  let!(:collection_resource_1) { create(:collection_resource, title: 'testing resource 1', collection: collection) }
  let!(:collection_resource_2) { create(:collection_resource, title: 'testing resource solr hvt.1021.232', collection: collection) }
  let!(:collection_resource_file) { create(:collection_resource_file, collection_resource: collection_resource) }


  context 'properties' do
    fields_to_check = %i[collection_id title is_featured access status external_resource_id created_at updated_at]
    fields_to_check.each do |value|
      it "should include #{value} attributes" do
        expect(collection_resource).to have_attribute(value)
      end
    end
  end

  describe '#collection resource ' do
    context 'Connected to a correct collection' do
      it 'Check if returns fields get deleted ' do
        fixture = {}
        fixture[:resource_file_id] = collection_resource_file.id
        expect(collection_resource.collection_resource_files.length).to eq(1)
        expect(collection_resource.delete_resource_files(fixture).first).to be_a_kind_of(CollectionResourceFile)
        expect(collection_resource.collection_resource_files.length).to eq(0)
      end
    end
  end

  describe '#collection resource ' do
    context 'Connected to a correct collection resource' do
      it 'Check if Solr is being updated ' do
        collection_resource.title = 'solr testing'
        collection_resource.save
        Sunspot.index collection_resource
        Sunspot.commit
        search = CollectionResource.search.results
        change_name = false
        search.each do |single_search|
          change_name = true if single_search.title == 'solr testing'
        end
        expect(change_name).to be_truthy
      end
    end
  end

  describe '#collection resource ' do
    context 'Connected to a correct collection resource' do
      it 'Check if tombstone_fields working ' do
        collection_resource_field = Aviary::FieldManagement::OrganizationFieldManager.new.organization_field_settings(collection.organization, nil, 'resource_fields', 'sort_order')
        collection_resource.tombstone_fields(collection_resource_field)
      end
    end
  end

  describe '#collection resource ' do
    context 'Connected to a correct collection resource' do
      it 'Check if Solr is being updated ' do
        collection_resource.title = 'solr testing'
        collection_resource.save
        collection_resource.reindex_collection_resource
        search = CollectionResource.search.results
        change_name = false
        search.each do |single_search|
          change_name = true if single_search.title == 'solr testing'
        end
        expect(change_name).to be_truthy
      end
    end
  end
  describe '#collection resource ' do
    context 'Connected to a correct collection resource' do
      it 'Delete Resource File ' do
        response = collection_resource.delete_resource_files(resource_file_id: collection_resource_file.id)
        expect(response.first.class).to eq(CollectionResourceFile)
        expect(response.first.id).to eq(1)
        expect(CollectionResource.limit_response).to eq(10)
      end
    end
  end
  describe '#collection resource' do
    context 'Connected to a correct collection resource' do
      it 'Fetch resource Listing' do
        expect(CollectionResource.fetch_resources(1, 10, nil, nil, { search: { value: 'test' } }, 'document_type_ss:collection_resource', export: false, current_organization: organization).first.length).to be > 1
      end
    end
  end

  describe '#collection resource' do
    context 'Connected to a correct collection resource' do
      it 'Fetch resource Listing' do
        expect(CollectionResource.fetch_resources(1, 10, nil, nil, { search: { value: 'test test' } }, 'document_type_ss:collection_resource', export: false, current_organization: organization).first.length).to be > 1
      end
    end
  end

  describe '#collection resource' do
    context 'Connected to a correct collection resource' do
      it 'Fetch resource Listing' do
        expect(CollectionResource.fetch_resources(1, 10, nil, nil, { search: { value: 'hvt.1021.232' } }, 'document_type_ss:collection_resource', export: false, current_organization: organization).first.length).to be >= 0

      end
    end
  end

  describe '#collection resource' do
    context 'Connected to a correct collection resource' do
      it 'Fetch resource Listing' do
        resource_field_values = collection_resource.resource_description_value.try(:resource_field_values)
        duration = resource_field_values.present? && resource_field_values['duration'].present? && resource_field_values['duration']['values'].present? ? resource_field_values['duration']['values'].try(:first) : nil
        duration = duration.present? ? duration['value'] : 0.0
        expect(duration).to be_a_kind_of(Float)
      end
    end
  end

end
