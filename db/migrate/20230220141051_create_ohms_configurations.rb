class CreateOhmsConfigurations < ActiveRecord::Migration[6.1]
  def change
    create_table :ohms_configurations do |t|
      t.references :organization
      t.text :configuration
      t.timestamps
    end
  end
end
