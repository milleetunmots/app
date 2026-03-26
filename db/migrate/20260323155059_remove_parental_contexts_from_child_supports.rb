class RemoveParentalContextsFromChildSupports < ActiveRecord::Migration[7.0]
  def change
    remove_column :child_supports, :parental_contexts, :string
  end
end
