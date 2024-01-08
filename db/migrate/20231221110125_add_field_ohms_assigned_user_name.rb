class AddFieldOhmsAssignedUserName < ActiveRecord::Migration[6.1]
    def change
      add_column :interviews, :ohms_assigned_user_name, :string, default: nil
      Organization.all.each do |org|
        interview_search_column = JSON.parse(org.interview_search_column) if org.interview_search_column.present?
        if interview_search_column.present?
          display_keys = interview_search_column.map { |_key, single_column| single_column['value'] }
          begin
            unless display_keys.include?('ohms_assigned_user_name_ss')
              interview_search_column[interview_search_column.count] = { 'status' => 'true', 'value' => 'ohms_assigned_user_name_ss', 'sort_name' => 'true' }
            end
  
            org.update(interview_search_column: interview_search_column.to_json)
          rescue StandardError => exception
            puts "\nUnable to update display and search columns for organization with id: #{org.id} and name: #{org.name}\nError => #{exception}"
          end
        end
      end
      failed = []
      Interviews::Interview.where.not(ohms_assigned_user_id: nil).each do |obj|
        begin
          user = User.find(obj.ohms_assigned_user_id)
          if user.present?
            obj.update(ohms_assigned_user_name: user.full_name)
            Sunspot.index obj
            Sunspot.commit
            puts obj.id
          end
        rescue StandardError => error
          puts error
          failed << obj.id
        end
      end
    end
  end