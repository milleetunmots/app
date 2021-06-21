class AddToCallToChildSupports < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :to_call, :boolean
  end
end
