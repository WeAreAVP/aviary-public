class RemoveMaxSizeInTbFromPlans < ActiveRecord::Migration[5.1]
  def change
    remove_column :plans, :max_size_in_tb, :float
  end
end
