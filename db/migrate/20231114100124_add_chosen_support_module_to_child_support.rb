class AddChosenSupportModuleToChildSupport < ActiveRecord::Migration[6.0]
  def change
    add_reference :child_supports, :module2_chosen_by_parents, foreign_key: { to_table: :support_modules }
    add_reference :child_supports, :module3_chosen_by_parents, foreign_key: { to_table: :support_modules }
    add_reference :child_supports, :module4_chosen_by_parents, foreign_key: { to_table: :support_modules }
    add_reference :child_supports, :module5_chosen_by_parents, foreign_key: { to_table: :support_modules }
  end
end
