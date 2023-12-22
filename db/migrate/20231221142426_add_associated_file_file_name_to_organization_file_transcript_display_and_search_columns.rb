class AddAssociatedFileFileNameToOrganizationFileTranscriptDisplayAndSearchColumns < ActiveRecord::Migration[6.1]
  def up
    Organization.all.each do |org|
      display_columns = JSON.parse(org.transcript_display_column)
      search_columns = JSON.parse(org.transcript_search_column)

      next unless display_columns.present? && search_columns.present?

      field_settings = {
        status: 'true',
        value: 'associated_file_file_name_ss',
        sort_name: true 
      }
      display_columns['columns_status'][display_columns['columns_status'].length.to_s] = field_settings
      search_columns[search_columns.length.to_s] = field_settings

      org.update(transcript_display_column: display_columns.to_json, transcript_search_column: search_columns.to_json)
    end
  end
end
