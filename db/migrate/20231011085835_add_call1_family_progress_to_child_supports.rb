class AddCall1FamilyProgressToChildSupports < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :call1_family_progress, :string
  end
end
