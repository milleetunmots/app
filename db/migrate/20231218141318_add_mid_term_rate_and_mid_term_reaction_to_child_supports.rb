class AddMidTermRateAndMidTermReactionToChildSupports < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :parent_mid_term_rate, :integer
    add_column :child_supports, :parent_mid_term_reaction, :string
  end
end
