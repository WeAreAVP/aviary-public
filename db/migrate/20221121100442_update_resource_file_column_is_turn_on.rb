class UpdateResourceFileColumnIsTurnOn < ActiveRecord::Migration[6.1]
  def change
    Organization.all.each do |org|
      resource_file_display_column = JSON.parse(org.resource_file_display_column) if org.resource_file_display_column.present?
      if resource_file_display_column.present?
        display_keys = resource_file_display_column['columns_status'].map { |_key, single_column| single_column['value'] }
        begin
          unless display_keys.include?('is_cc_on_ss')
            resource_file_display_column['columns_status'][resource_file_display_column['columns_status'].count] = { 'status' => 'true', 'value' => 'is_cc_on_ss', 'sort_name' => 'true' }
          end
          org.update(resource_file_display_column: resource_file_display_column.to_json)
        rescue StandardError => exception
          puts "\nUnable to update display columns for organization with id: #{org.id} and name: #{org.name}\nError => #{exception}"
        end
      end
    end
  end
end
