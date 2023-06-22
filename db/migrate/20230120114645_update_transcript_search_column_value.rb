# UpdateTranscriptSearchColumnValue
#
class UpdateTranscriptSearchColumnValue < ActiveRecord::Migration[6.1]
  def change
    Organization.all.each do |org|
      transcript_search_column = JSON.parse(org.transcript_search_column) if org.transcript_search_column.present?
      if transcript_search_column.present?
        search_keys = transcript_search_column.map { |_key, single_column| single_column['value'] }
        begin
          unless search_keys.include?('associated_file_content_type_ss')
            transcript_search_column[transcript_search_column.count] = { 'value' => 'associated_file_content_type_ss', 'status' => 'true' }
          end
          org.update(transcript_search_column: transcript_search_column.to_json)
        rescue StandardError => exception
          puts "\nUnable to update search columns for organization with id: #{org.id} and name: #{org.name}\nError => #{exception}"
        end
      end
    end
  end
end
