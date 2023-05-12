class AddCaptionToOrganizationTranscriptDisplayAndSearchColumns < ActiveRecord::Migration[6.1]
  def change
    Organization.all.each do |org|
        transcript_display_column = JSON.parse(org.transcript_display_column) if org.transcript_display_column.present? 
        transcript_search_column = JSON.parse(org.transcript_search_column) if org.transcript_search_column.present?
      if transcript_display_column.present? && transcript_search_column.present?
        display_keys = transcript_display_column['columns_status'].map { |_key, single_column| single_column['value'] }
        search_keys = transcript_search_column.map { |_key, single_column| single_column['value'] }
        begin
          unless display_keys.include?('is_caption_ss')
            transcript_display_column['columns_status'][transcript_display_column['columns_status'].count] = { 'status' => 'true', 'value' => 'is_caption_ss', 'sort_name' => 'true' }
          end
          unless display_keys.include?('is_caption_ss')
            transcript_search_column[transcript_search_column.count] = { 'status' => 'true', 'value' => 'is_caption_ss' }
          end
          org.update(transcript_display_column: transcript_display_column.to_json, transcript_search_column: transcript_search_column.to_json)
        rescue StandardError => exception
          puts "\nUnable to update display and search columns for organization with id: #{org.id} and name: #{org.name}\nError => #{exception}" 
        end
      end
    end
  end
end