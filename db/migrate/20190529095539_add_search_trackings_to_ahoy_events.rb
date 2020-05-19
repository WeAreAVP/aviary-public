class AddSearchTrackingsToAhoyEvents < ActiveRecord::Migration[5.1]
  def change
    add_reference :ahoy_events, :search_tracking, foreign_key: true
  end
  
  def remove
    remove_reference :ahoy_events, :search_tracking
  end
end
