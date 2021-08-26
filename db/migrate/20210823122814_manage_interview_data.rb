class ManageInterviewData < ActiveRecord::Migration[5.2]
  def change
    Organization.all.each do |single_org|
      single_org.interview_display_column = nil
      single_org.interview_search_column = nil
      single_org.save
    end
    interview = Interviews::Interview.all
    if interview.present?
      interview.each do |single_interview|
        single_interview.save
      end
    end
  end
end
