require 'rails_helper'

RSpec.describe CollectionsController, type: :controller do
  let(:collection) { create(:collection) }
  let(:collection_resource_1) { create(:collection_resource, collection: collection) }
  let(:collection_resource_2) { create(:collection_resource, collection: collection) }
  let(:collection_resource_file_1) { create(collection_resource_file, collection_resource: collection_resource_1) }
  let(:collection_resource_file_2) { create(collection_resource_file, collection_resource: collection_resource_1) }
  let(:collection_resource_file_3) { create(collection_resource_file, collection_resource: collection_resource_2) }
  let(:collection_resource_file_4) { create(collection_resource_file, collection_resource: collection_resource_2) }
  let(:collection_resource_file_5) { create(collection_resource_file, collection_resource: collection_resource_2) }

  before do
    request[:subdomain] = collection.organization.url
    allow(controller).to receive(:current_organization).and_return(collection.organization)
    allow(controller).to receive(:current_user).and_return(collection.organization.user)
    sign_in(collection.organization.user)
    allow(controller).to receive(:authenticate_user!).and_return(true)
  end

  describe "Index" do
    it "has a 200 status code with current organization" do
      organization = collection.organization
      allow(controller).to receive(:current_organization).and_return(organization)
      allow(controller).to receive(:current_user).and_return(organization.user)
      get :index
      expect(response.status).to eq(200)
    end

    it "has a 200 status code with current organization" do
      organization = collection.organization
      allow(controller).to receive(:current_organization).and_return(organization)
      allow(controller).to receive(:current_user).and_return(organization.user)
      get :index
      expect(response.status).to eq(200)
    end
  end

  describe "New" do
    it "has a 200 status code" do
      get :new
      expect(response.status).to eq(200)
    end

    it "has a 200 status code with current organization" do
      get :new
      expect(assigns(:collection)).to be_a_new(Collection)
    end
  end

  describe "Create" do
    it "will create collection when params are provided" do
      post :create, params: { collection: { title: 'Test Collection', about: 'Testing', is_public: true, is_featured: true } }
      expect(assigns(:collection).title).to eq('Test Collection')
    end

    it "will not create collection when params are not provided" do
      post :create, params: { collection: { is_public: true, is_featured: true } }
      expect(assigns(:collection).title).to eq(nil)
    end
  end

  describe "edit" do
    context "when not an xhr request" do
      it "will return collection field sort" do
        collection_field_sort = Aviary::FieldManagement::OrganizationFieldManager.new.organization_field_settings(collection.organization, nil, 'collection_fields', 'sort_order')
        fields = Rails.configuration.default_fields['fields']['collection']
        get :edit, params: { id: collection.id }
        expect(fields.first).to eq(collection_field_sort.first)
      end

      it "will return collection resource field sort" do
        collection_resource_field = Aviary::FieldManagement::OrganizationFieldManager.new.organization_field_settings(collection.organization, nil, 'resource_fields', 'sort_order')
        fields = Rails.configuration.default_fields['fields']['resource']
        get :edit, params: { id: collection.id }
        expect(fields['title']).to eq(collection_resource_field['title'])
      end
      #
      it "will return collection field sort" do
        collection_resource = create(:collection_resource, title: 'testing resource', collection: collection)
        get :edit, params: { id: collection.id }
        expect(assigns(:collection_resource)).to eq(collection_resource)
      end
    end
  end

  describe "update" do
    context "when collection update" do
      it "will create collection when params are provided" do

        fields = Aviary::FieldManagement::OrganizationFieldManager.new.organization_field_settings(collection.organization, nil, 'collection_fields', 'sort_order')
        updated_values = {}
        fields.each_with_index do |(system_name, _single_collection_field), _index|
          updated_values[system_name] ||= {}
          updated_values[system_name]['values'] ||= []
          updated_values[system_name]['system_name'] = system_name
          value = "dummy title"
          updated_values[system_name]['values'] << { "vocab_value" => "", "value" => value, "collection_resource_id" => collection.id }
        end

        put :update, params: { id: collection.id, collection: { title: 'Test Collection1', about: 'Testing', is_public: true, is_featured: true,
                                                                collection_field_values_attributes: [{ collection_field_id: fields.first.second['system_name'],
                                                                                                       value: 'hello' }] },
                               collection_settings: updated_values }
        expect(assigns(:collection).title).to eq('Test Collection1')
      end
    end
  end

  describe "list_resources" do
    context "when collection list_resources" do
      it "list_resources" do
        fields = Aviary::FieldManagement::OrganizationFieldManager.new.organization_field_settings(collection.organization, nil, 'collection_fields', 'sort_order')
        updated_values = {}
        fields.each_with_index do |(system_name, _single_collection_field), _index|
          updated_values[system_name] ||= {}
          updated_values[system_name]['values'] ||= []
          updated_values[system_name]['system_name'] = system_name
          value = "dummy title"
          updated_values[system_name]['values'] << { "vocab_value" => "", "value" => value, "collection_resource_id" => collection.id }
        end
        put :list_resources, params: { id: collection.id, collection: { title: 'Test Collection1', about: 'Testing', is_public: true, is_featured: true,
                                                                        collection_field_values_attributes: [{ collection_field_id: fields.first.second['system_name'], value: 'hello' }] }, collection_settings: updated_values }
        assigns(:collection).title.include?('title')
      end
    end
  end

  describe "update_sort_fields" do
    it "will return collection" do
      collection_resource_field = Aviary::FieldManagement::OrganizationFieldManager.new.organization_field_settings(collection.organization, nil, 'collection_fields', 'sort_order')
      updated_settings = {}
      collection_resource_field.each_with_index do |(system_name, single_collection_field), index|
        unless index != 0
          updated_settings[system_name] = { field_id: system_name, is_visible: true, is_tombstone: false }.as_json
        else
          updated_settings[system_name] = single_collection_field
        end
      end
      get :update_sort_fields, xhr: true, params: { id: collection.id, collection_resource_field: updated_settings }
      expect(JSON.parse(response.body)['status']).to eq('success')
    end
  end

  describe "Delete Destroy" do
    it "has a 302 status code" do
      delete :destroy, params: { id: collection.id }
      expect(response.status).to eq(302)
      expect(Collection.all).to be_empty
    end
  end

  describe "Show" do
    it "has a 200 status code with current organization" do
      get :show, params: { id: collection.id }
      organization = collection.organization
      allow(controller).to receive(:current_organization).and_return(organization)
      allow(controller).to receive(:current_user).and_return(organization.user)
      expect(response.status).to eq(200)
    end
  end

  describe "Bulk edit" do
    let(:collection_with_resource) { create(:collection_with_multiple_files) }
    it "Bulk Resource List" do
      request.accept = "application/json"
      get :bulk_resource_list, params: { collection_resource_id: collection_with_resource.collection_resources.first.id, ids: collection_with_resource.collection_resources.pluck(:id), status: '1', bulk: 'add' }
      expect(response.status).to eq(200).or eq(202)
    end

    it "Bulk Edit Operation" do
      request.accept = "application/json"
      session[:resource_list_bulk_edit] = collection_with_resource.collection_resources.pluck(:id)
      post :bulk_edit_operation, params: { bulk_edit: { type_of_bulk_operation: 'change_media_file_status', status: 'access_private' } }
      expect(response.status).to eq(200).or eq(202)
    end

    it "Bulk Edit Operation Collection change" do
      request.accept = "application/json"
      collection_resource = create(:collection_resource, collection: collection, is_featured: false)
      session[:resource_list_bulk_edit] = collection_with_resource.collection_resources.pluck(:id)
      post :bulk_edit_operation, params: { bulk_edit_status: 'access_restricted', bulk_edit_type_of_bulk_operation: 'assign_to_collection', bulk_edit_featured: 'Yes', bulk_edit_collections: collection.id, ids: [collection_resource.id] }
      expect(response.status).to eq(200).or eq(202)
    end

    it "Fetch Bulk Edit Resource List" do
      session[:resource_list_bulk_edit] = collection_with_resource.collection_resources.pluck(:id)
      get :fetch_bulk_edit_resource_list, params: {}
      expect(response.status).to eq(200).or eq(202)
    end

    it "Update Progress" do
      request.accept = "application/json"
      get :update_progress, params: { bulk_edit_type_of_bulk_operation: 'change_status', ids: collection_with_resource.collection_resources.pluck(:id) }
      expect(response.status).to eq(200).or eq(202)
    end
  end

  describe "Export CSV" do
    it "should return csv" do
      get :export, params: { export_type: 'collection' }
      response.header['Content-Type'].should eql('csv')
      response.header['Content-Disposition'].include?("collection")
    end

    it "should return collection csv" do
      get :export, params: { export_type: 'collection' }
      response.header['Content-Disposition'].include?("collection")
    end

    it "should return resource csv" do
      get :export, params: { export_type: 'resources' }
      response.header['Content-Disposition'].include?("collection_resources")
    end

    it "should have all the metadata fields with proper syntax" do
      collection_resource_1.create_resource_description_value(resource_field_values: {
        "date"=>{"values"=>[{"value"=>"2013-07-10", "vocab_value"=>"issued"}], "system_name"=>"date"},
        "type"=>{"values"=>[{"value"=>"Science", "vocab_value"=>""}], "system_name"=>"type"},
        "agent"=>{"values"=>[{"value"=>"Derek Muller", "vocab_value"=>""}], "system_name"=>"agent"},
        "format"=>{"values"=>[{"value"=>"video", "vocab_value"=>""}], "system_name"=>"format"},
        "source"=>{"values"=>[{"value"=>"Youtube", "vocab_value"=>""}], "system_name"=>"source"},
        "creator"=>{"values"=>[{"value"=>"Derek Muller", "vocab_value"=>""}], "system_name"=>"creator"},
        "keyword"=>{"values"=>[{"value"=>"Transistor", "vocab_value"=>""}, {"value"=>"Computer", "vocab_value"=>""}, {"value"=>"Quantum", "vocab_value"=>""}], "system_name"=>"keyword"},
        "subject"=>{"values"=>[{"value"=>"Computer Science", "vocab_value"=>"other"}], "system_name"=>"subject"},
        "coverage"=>{"values"=>[{"value"=>"Global", "vocab_value"=>"spatial"}], "system_name"=>"coverage"},
        "language"=>{"values"=>[{"value"=>"English", "vocab_value"=>"primary"}], "system_name"=>"language"},
        "relation"=>{"values"=>[{"value"=>"From Transistors to Quantum Computers", "vocab_value"=>"is part of"}], "system_name"=>"relation"},
        "publisher"=>{"values"=>[{"value"=>"Veritasium", "vocab_value"=>""}], "system_name"=>"publisher"},
        "identifier"=>{"values"=>[{"value"=>"IcrBqCFLHIY", "vocab_value"=>"other"}], "system_name"=>"identifier"},
        "description"=>
          {"values"=>
            [{"value"=>
              "<p><span style=\"color: #030303; font-family: Roboto, Arial, sans-serif; font-size: 14px; white-space: pre-wrap; background-color: #f9f9f9;\">When I mentioned to people that I was doing a video on transistors, they would say \"as in a transistor radio?\" Yes! That's exactly what I mean, but it goes so much deeper than that. After the transistor was invented in 1947 one of the first available consumer technologies it was applied to was radios, so they could be made portable and higher quality. Hence the line in 'Brown-eyed Girl' - \"going down to the old mine with a transistor radio.\" But more important to our lives today, the transistor made possible the microcomputer revolution, and hence the Internet, and also TVs, mobile phones, fancy washing machines, dishwashers, calculators, satellites, projectors etc. etc. A transistor is based on semiconductor material, usually silicon, which is 'doped' with impurities to carefully change its electrical properties. These n and p-type semiconductors are then put together in different configurations to achieve a desire d electrical result. And in the case of the transistor, this is to make a tiny electrical switch. These switches are then connected together to perform computations, store information, and basically make everything electrical work intelligently.</span></p>",
              "vocab_value"=>"general"}],
          "system_name"=>"description"},
        "rights_statement"=>
          {"values"=>
            [{"value"=>
              "<p style=\"margin: 0.25rem 0px 0.75rem; color: #1f1f1f; font-family: 'Google Sans Text', Roboto, 'Helvetica Neue', Helvetica, sans-serif;  font-size: 14px; background-color: #ffffff;\">The ability to mark uploaded videos with a Creative Commons license is available to all creators.<p><p style=\"margin: 0.25rem 0px 0.75rem; color: #1f1f1f; font-family: 'Google Sans Text', Roboto, 'Helvetica Neue', Helvetica, sans-serif; font-size: 14px; background-color: #ffffff;\">The standard YouTube license remains the default setting for all uploads. To review the terms of the standard YouTube license,&nbsp;refer to our&nbsp;<a style=\"color: #0b57d0; text-decoration-line: none;\" href=\"https://www.youtube.com/static?template=terms\" target=\"_blank\" rel=\"noopener\">Terms of Service</a>.</p><p style=\"margin: 0.25rem 0px 0.75rem; color: #1f1f1f; font-family: 'Google Sans Text', Roboto, 'Helvetica Neue', Helvetica, sans-serif; font-size: 14px; background-color: #ffffff;\">Creative Commons licenses can only be used on 100%&nbsp;original content. If there's a&nbsp; <a style=\"color: #0b57d0; text-decoration-line: none;\" href=\"https://support.google.com/youtube/answer/6013276\" rel=\"noopener\">Content ID</a>&nbsp;claim on your video,&nbsp;you cannot mark your video with the Creative Commons license.</p><p style=\"margin: 0.25rem 0px 0.75rem; color: #1f1f1f; font-family: 'Google Sans Text', Roboto, 'Helvetica Neue', Helvetica, sans-serif; font-size: 14px; background-color: #ffffff;\">By marking your original video with a Creative Commons license, you're granting the entire YouTube community the right to reuse and edit that video.</p>",
              "vocab_value"=>""}],
          "system_name"=>"rights_statement"},
        "source_metadata_uri"=>{"values"=>[{"value"=>"https://www.youtube.com/watch?v=IcrBqCFLHIY", "vocab_value"=>""}], "system_name"=>"source_metadata_uri"}
      })
      collection_resource_2.create_resource_description_value(resource_field_values: {
        "date"=>{"values"=>[{"value"=>"2021-12-23", "vocab_value"=>""}], "system_name"=>"date"},
        "agent"=>{"values"=>[{"value"=>"Usman Javaid", "vocab_value"=>""}], "system_name"=>"agent"},
        "coverage"=>{"values"=>[{"value"=>"Testing", "vocab_value"=>"spatial"}], "system_name"=>"coverage"},
        "description"=>{"values"=>[{"value"=>"<p>Test Testing</p>", "vocab_value"=>""}], "system_name"=>"description"}
      })
      collection_resource_1.reindex_collection_resource
      collection_resource_2.reindex_collection_resource
      get :export, params: { export_type: 'resources' }
      csv_array = response.body.split("\n").map { |line| line.split(',') }

      expect(csv_array[0]).to eq(["aviary ID", "Resource User Key", "Title", "Source Metadata URI", "Duration", "Publisher", "Rights Statement", "Source", "Agent", "Date","Coverage", "Language", "Description", "Format", "Identifier", "Relation", "Subject", "Keyword", "Type", "Access", "Preferred Citation","Collection Title", "PURL", "URL", "Embed"])

      collection_resource_1.reload
      data = csv_array.filter { |line| line[0] == collection_resource_1.id.to_s }.first
      expect(data).to eq([collection_resource_1.id.to_s, "\"\"", collection_resource_1.title, "https://www.youtube.com/watch?v=IcrBqCFLHIY", "00:00:00", "Veritasium", "\"<p style=\"\"margin: 0.25rem 0px 0.75rem; color: #1f1f1f; font-family: 'Google Sans Text'", " Roboto", " 'Helvetica Neue'", " Helvetica", " sans-serif;  font-size: 14px; background-color: #ffffff;\"\">The ability to mark uploaded videos with a Creative Commons license is available to all creators.<p><p style=\"\"margin: 0.25rem 0px 0.75rem; color: #1f1f1f; font-family: 'Google Sans Text'", " Roboto", " 'Helvetica Neue'", " Helvetica", " sans-serif; font-size: 14px; background-color: #ffffff;\"\">The standard YouTube license remains the default setting for all uploads. To review the terms of the standard YouTube license", "&nbsp;refer to our&nbsp;<a style=\"\"color: #0b57d0; text-decoration-line: none;\"\" href=\"\"https://www.youtube.com/static?template=terms\"\" target=\"\"_blank\"\" rel=\"\"noopener\"\">Terms of Service</a>.</p><p style=\"\"margin: 0.25rem 0px 0.75rem; color: #1f1f1f; font-family: 'Google Sans Text'", " Roboto", " 'Helvetica Neue'", " Helvetica", " sans-serif; font-size: 14px; background-color: #ffffff;\"\">Creative Commons licenses can only be used on 100%&nbsp;original content. If there's a&nbsp; <a style=\"\"color: #0b57d0; text-decoration-line: none;\"\" href=\"\"https://support.google.com/youtube/answer/6013276\"\" rel=\"\"noopener\"\">Content ID</a>&nbsp;claim on your video", "&nbsp;you cannot mark your video with the Creative Commons license.</p><p style=\"\"margin: 0.25rem 0px 0.75rem; color: #1f1f1f; font-family: 'Google Sans Text'", " Roboto", " 'Helvetica Neue'", " Helvetica", " sans-serif; font-size: 14px; background-color: #ffffff;\"\">By marking your original video with a Creative Commons license", " you're granting the entire YouTube community the right to reuse and edit that video.</p>\"", "Youtube", "Derek Muller", "issued::2013-07-10", "spatial::Global", "primary::English", "\"general::<p><span style=\"\"color: #030303; font-family: Roboto", " Arial", " sans-serif; font-size: 14px; white-space: pre-wrap; background-color: #f9f9f9;\"\">When I mentioned to people that I was doing a video on transistors", " they would say \"\"as in a transistor radio?\"\" Yes! That's exactly what I mean", " but it goes so much deeper than that. After the transistor was invented in 1947 one of the first available consumer technologies it was applied to was radios", " so they could be made portable and higher quality. Hence the line in 'Brown-eyed Girl' - \"\"going down to the old mine with a transistor radio.\"\" But more important to our lives today", " the transistor made possible the microcomputer revolution", " and hence the Internet", " and also TVs", " mobile phones", " fancy washing machines", " dishwashers", " calculators", " satellites", " projectors etc. etc. A transistor is based on semiconductor material", " usually silicon", " which is 'doped' with impurities to carefully change its electrical properties. These n and p-type semiconductors are then put together in different configurations to achieve a desire d electrical result. And in the case of the transistor", " this is to make a tiny electrical switch. These switches are then connected together to perform computations", " store information", " and basically make everything electrical work intelligently.</span></p>\"", "video", "other::IcrBqCFLHIY", "is part of::From Transistors to Quantum Computers", "other::Computer Science", "Transistor|Computer|Quantum", "Science", "access_public", "", collection_resource_1.collection.title, "http://localhost/r/#{collection_resource_1.noid}", "http://localhost/collections/#{collection_resource_1.collection.id}/collection_resources/#{collection_resource_1.id}", "<iframe src='http://localhost/collections/#{collection_resource_1.collection.id}/collection_resources/#{collection_resource_1.id}?embed=true' height='400' width='1200' style='width: 100%'></iframe>"])

      data = csv_array.filter { |line| line[0] == collection_resource_2.id.to_s }.first
      expect(data).to eq([collection_resource_2.id.to_s, "\"\"", collection_resource_2.title, "\"\"", "00:00:00", "\"\"", "", "\"\"", "Usman Javaid", "2021-12-23", "spatial::Testing", "\"\"", "<p>Test Testing</p>", "\"\"", "\"\"", "\"\"", "\"\"", "\"\"", "\"\"", "access_public", "", collection_resource_2.collection.title, "http://localhost/r/#{collection_resource_2.noid}", "http://localhost/collections/#{collection_resource_2.collection.id}/collection_resources/#{collection_resource_2.id}", "<iframe src='http://localhost/collections/#{collection_resource_2.collection.id}/collection_resources/#{collection_resource_2.id}?embed=true' height='400' width='1200' style='width: 100%'></iframe>"])
    end
  end
end
