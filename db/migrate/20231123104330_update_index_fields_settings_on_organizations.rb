class UpdateIndexFieldsSettingsOnOrganizations < ActiveRecord::Migration[6.1]
  def change
    Organization.all.each do |org|
      if org.organization_field.present?
        index_fields_settings = org.organization_field.index_fields
        index_fields_settings.each do |key, _value|
          unless %w[title keywords subjects gps hyperlink].include?(index_fields_settings[key]['system_name'])
            index_fields_settings[key]['vocabulary'] = []
          end
        end

        %w[publisher contributor segment_date identifier rights].each_with_index do |system_name, index|
          index_fields_settings[system_name] = {
            system_name: system_name,
            display_name: system_name.capitalize,
            sort_order: 9 + index + 1,
            display: true,
            required: false,
            vocabulary: []
          }
        end

        org.organization_field.update(index_fields: index_fields_settings)
      end
    end
  end
end
