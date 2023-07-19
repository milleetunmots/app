class AddModuleSuivantToBubbleModule < ActiveRecord::Migration[6.0]
  def change
    add_reference :bubble_modules, :module_suivant, foreign_key: { to_table: :bubble_modules }
  end
end
