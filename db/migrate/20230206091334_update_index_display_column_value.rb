class UpdateIndexDisplayColumnValue < ActiveRecord::Migration[6.1]
  def change
    Organization.all.each do |org|
      file_index_display_column = JSON.parse(org.file_index_display_column) if org.file_index_display_column.present?
      if file_index_display_column.present?
        display_keys = file_index_display_column['columns_status'].map { |_key, single_column| single_column['value'] }
        begin
          unless display_keys.include?('associated_file_content_type_ss')
            file_index_display_column['columns_status'][file_index_display_column['columns_status'].count] = { 'status' => 'true', 'value' => 'associated_file_content_type_ss', 'sort_name' => 'true' }
          end
          org.update(file_index_display_column: file_index_display_column.to_json)
        rescue StandardError => exception
          puts "\nUnable to update display columns for organization with id: #{org.id} and name: #{org.name}\nError => #{exception}"
        end
      end
    end
  end
end
