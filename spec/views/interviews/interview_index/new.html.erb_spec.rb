require 'rails_helper'

RSpec.describe "interviews/interview_index/new", type: :view do
  include Devise::Test::ControllerHelpers

  let(:collection_resource) { create(:collection_resource) }
  let(:collection_resource_file) { create :collection_resource_file, collection_resource: collection_resource }
  let(:file_index) { create :file_index, collection_resource_file: collection_resource_file }
  let(:index_point) { create :file_index_point, file_index: file_index }
  let(:sample_file) { fixture_file_upload("#{Rails.root}/spec/fixtures/small.mp4", 'video/mp4') }

  before(:each) do
    assign(:resource_file, collection_resource_file)
    assign(:collection_resource, collection_resource)
    assign(:current_organization, collection_resource.collection.organization)
    assign(:current_user, collection_resource.collection.organization.user)
  end

  it "renders page successfully when adding a new index point " do
    assign(:file_index_point, FileIndexPoint.new)
    render

    expect(rendered).to match(collection_resource.title)
    expect(rendered).to include("Return To Index")
    expect(rendered).to include("Save")
  end

  it "renders page successfully when editing existing index point page" do
    assign(:file_index, file_index)
    assign(:file_index_point, index_point)
    render

    expect(rendered).to match(collection_resource.title)
    expect(rendered).to include("Return To Index")
    expect(rendered).to include("Save")

    expect(rendered).to match(index_point.title)
    expect(rendered).to match(index_point.synopsis)
    expect(rendered).to match(index_point.partial_script)
    expect(rendered).to match(index_point.gps_latitude)
    expect(rendered).to match(index_point.gps_longitude)
    expect(rendered).to match(index_point.gps_zoom)
    expect(rendered).to match(index_point.gps_description)
    expect(rendered).to match(index_point.hyperlink)
    expect(rendered).to match(index_point.subjects)
    expect(rendered).to match(index_point.keywords)
  end
end
