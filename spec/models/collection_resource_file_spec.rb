require "rails_helper"

RSpec.describe CollectionResourceFile, type: :model do
  let(:collection_resource_file) { build :collection_resource_file, attributes_for(:collection_resource_file, :check_ffmpeg) }
  let(:subscription) { build :subscription }
  context 'Check CollectionResourceFile Model and methods' do
    fields_to_check = %i[collection_resource_id sort_order embed_code embed_type file_display_name resource_file_file_name resource_file_content_type resource_file_file_size resource_file_updated_at thumbnail_file_name thumbnail_content_type thumbnail_file_size thumbnail_updated_at]
    fields_to_check.each do |value|
      it "should include #{value} attributes" do
        expect(collection_resource_file).to have_attribute(value)
      end
    end
    it "should include validate file generate thumb" do
      subscription.organization = collection_resource_file.collection_resource.collection.organization
      subscription.save
      expect(collection_resource_file.valid?).to be(true)
    end
    it "has 3 different player types" do
      expect(CollectionResourceFile::PlayerType.for_select.count).to eq 4
    end
    it "has 3 different player types" do
      expect(CollectionResourceFile.embed_type_name(1)).to eq ('Youtube')
    end
    it "returns the file size" do
      expect(CollectionResourceFile.resource_file_size(collection_resource_file.collection_resource.collection.organization.id)).to be_truthy
    end
    it "set the bucket of the resource file" do
      expect(collection_resource_file.set_bucket).to be_truthy
    end
    it "default_values" do
      collection_resource_file.default_values
    end
    
    it "update_duration" do
      collection_resource_file.update_duration
    end

    it "update_storage" do
      collection_resource_file.update_storage
    end
    it "resource_file_size" do
      CollectionResourceFile.resource_file_size(collection_resource_file.collection_resource.collection.organization.id)
    end
    
    it "generate_thumbnail" do
      collection_resource_file.generate_thumbnail
    end
    
  end

end