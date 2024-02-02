class AddChosenSupportModule6ToChildSupport < ActiveRecord::Migration[6.1]
  def change
    add_reference :child_supports, :module6_chosen_by_parents, foreign_key: { to_table: :support_modules }
  end
end
