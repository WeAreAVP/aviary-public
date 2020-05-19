class AddEnableAutoscrollInCollections < ActiveRecord::Migration[5.1]
  def change
    add_column :collections, :enable_itc_autoscroll, :boolean, default: false
  end
end
