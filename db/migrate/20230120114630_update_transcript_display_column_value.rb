# UpdateTranscriptDisplayColumnValue
#
class UpdateTranscriptDisplayColumnValue < ActiveRecord::Migration[6.1]
  def change
    Organization.all.each do |org|
      transcript_display_column = JSON.parse(org.transcript_display_column) if org.transcript_display_column.present?
      if transcript_display_column.present?
        display_keys = transcript_display_column['columns_status'].map { |_key, single_column| single_column['value'] }
        begin
          unless display_keys.include?('associated_file_content_type_ss')
            transcript_display_column['columns_status'][transcript_display_column['columns_status'].count] = { 'status' => 'true', 'value' => 'associated_file_content_type_ss', 'sort_name' => 'true' }
          end
          org.update(transcript_display_column: transcript_display_column.to_json)
        rescue StandardError => exception
          puts "\nUnable to update display columns for organization with id: #{org.id} and name: #{org.name}\nError => #{exception}"
        end
      end
    end
  end
end
