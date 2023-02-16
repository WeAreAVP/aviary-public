class UpdateIndexSearchColumnValue < ActiveRecord::Migration[6.1]
  def change
    Organization.all.each do |org|
      file_index_search_column = JSON.parse(org.file_index_search_column) if org.file_index_search_column.present?
      if file_index_search_column.present?
        search_keys = file_index_search_column.map { |_key, single_column| single_column['value'] }
        begin
          unless search_keys.include?('associated_file_content_type_ss')
            file_index_search_column[file_index_search_column.count] = { 'value' => 'associated_file_content_type_ss', 'status' => 'true' }
          end
          org.update(file_index_search_column: file_index_search_column.to_json)
        rescue StandardError => exception
          puts "\nUnable to update search columns for organization with id: #{org.id} and name: #{org.name}\nError => #{exception}"
        end
      end
    end
  end
end
