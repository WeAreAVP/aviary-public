class AddRecordStatusInInterview < ActiveRecord::Migration[6.1]
  def change
    add_column :interviews, :record_status, :string, default: "Offline"
    Organization.all.each do |org|
      interview_display_column = JSON.parse(org.interview_display_column) if org.interview_display_column.present?
      if interview_display_column.present?
        display_keys = interview_display_column['columns_status'].map { |_key, single_column| single_column['value'] }
        begin
          unless display_keys.include?('record_status_is')
            interview_display_column['columns_status'][interview_display_column['columns_status'].count] = { 'status' => 'true', 'value' => 'record_status_is', 'sort_name' => 'true' }
          end

          org.update(interview_display_column: interview_display_column.to_json)
        rescue StandardError => exception
          puts "\nUnable to update display and search columns for organization with id: #{org.id} and name: #{org.name}\nError => #{exception}"
        end
      end
    end
    failed = []
    Interviews::Interview.order(id: :desc).all.each do |obj|
      begin
        Sunspot.index obj
        Sunspot.commit
        puts obj.id
      rescue StandardError => error
        puts error
        failed << obj.id
      end
    end
  end
end
