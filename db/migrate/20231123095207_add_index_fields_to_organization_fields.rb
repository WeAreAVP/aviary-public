class AddIndexFieldsToOrganizationFields < ActiveRecord::Migration[6.1]
  def change
    add_column :organization_fields, :index_fields, :json

    Organization.all.each do |org|
      puts "============#{org.id}=====>#{org.name}"
      if org.organization_field.present?
        org.organization_field.update(index_fields: {
          title: { system_name: 'title', display_name: 'Segment Title', sort_order: 0, display: true, required: true },
          synopsis: { system_name: 'synopsis', display_name: 'Segment Synopsis', sort_order: 1, display: true, required: false },
          partial_script: { system_name: 'partial_script', display_name: 'Partial Transcript', sort_order: 2, display: true, required: false },
          keywords: { system_name: 'keywords', display_name: 'Keywords', sort_order: 3, display: true, required: false },
          subjects: { system_name: 'subjects', display_name: 'Subjects', sort_order: 4, display: true, required: false },
          gps_latitude: { system_name: 'gps_latitude', display_name: 'GPS Latitude', sort_order: 5, display: true, required: false },
          gps_longitude: { system_name: 'gps_longitude', display_name: 'GPS Longitude', sort_order: 6, display: true, required: false },
          gps_description: { system_name: 'gps_description', display_name: 'GPS Description', sort_order: 7, display: true, required: false },
          gps_zoom: { system_name: 'gps_zoom', display_name: 'GPS Zoom', sort_order: 8, display: true, required: false },
          hyperlink: { system_name: 'hyperlink', display_name: 'Hyperlink', sort_order: 9, display: true, required: false },
          hyperlink_description: { system_name: 'hyperlink_description', display_name: 'Hyperlink Description', sort_order: 10, display: true, required: false },
        })
      end
    end
  end
end
