class UpdateInterviewColumnSettings < ActiveRecord::Migration[5.2]
  def change
    Organization.all.each do |single|
      single.interview_display_column = nil
      single.interview_search_column = nil
      single.save
    end
  end
end
