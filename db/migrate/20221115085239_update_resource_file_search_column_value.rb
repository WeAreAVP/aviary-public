class UpdateResourceFileSearchColumnValue < ActiveRecord::Migration[6.1]
  def change
    Organization.all.each do |org|
      resource_file_search_column = JSON.parse(org.resource_file_search_column) if org.resource_file_search_column.present?
      if resource_file_search_column.present?
        search_keys = resource_file_search_column.map { |_key, single_column| single_column['value'] }
        begin
          unless search_keys.include?('file_display_name_ss')
            resource_file_search_column[resource_file_search_column.count] = { 'value' => 'file_display_name_ss', 'status' => 'true' }
          end
          
          org.update(resource_file_search_column: resource_file_search_column.to_json)
        rescue StandardError => exception
          puts "\nUnable to update search columns for organization with id: #{org.id} and name: #{org.name}\nError => #{exception}"
        end
      end
    end
  end
end
