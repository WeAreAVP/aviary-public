class UpdateIndexFieldsInCollections < ActiveRecord::Migration[6.1]
  def change
    Organization.all.each do |org|
      if org.organization_field.present?
        org.organization_field.update(index_fields: {
          title: { system_name: 'title', display_name: 'Segment Title', sort_order: 0, display: true, required: true },
          synopsis: { system_name: 'synopsis', display_name: 'Segment Synopsis', sort_order: 1, display: true, required: false },
          partial_script: { system_name: 'partial_script', display_name: 'Partial Transcript', sort_order: 2, display: true, required: false },
          keywords: { system_name: 'keywords', display_name: 'Keywords', sort_order: 3, display: true, required: false },
          subjects: { system_name: 'subjects', display_name: 'Subjects', sort_order: 4, display: true, required: false },
          gps: { system_name: 'gps', display_name: 'GPS', sort_order: 5, display: true, required: false },
          hyperlink: { system_name: 'hyperlink', display_name: 'Hyperlink', sort_order: 9, display: true, required: false },
        })
      end
    end

    Collection.all.each do |col|
      index_fields = col.organization.organization_field.index_fields

      col.collection_fields_and_value.update(index_fields: index_fields) if col.collection_fields_and_value.present?
    end
  end
end
