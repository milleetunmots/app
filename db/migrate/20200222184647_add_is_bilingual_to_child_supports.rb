class AddIsBilingualToChildSupports < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :is_bilingual, :boolean
    add_column :child_supports, :second_language, :string
  end
end
