class AddParentalContextsToChildSupports < ActiveRecord::Migration[6.1]
  def change
    add_column :child_supports, :parental_contexts, :string, array: true
  end
end
