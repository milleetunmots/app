class ChangeChildFamilyNull < ActiveRecord::Migration[6.0]
  def change
    change_column_null(:children, :family_id, false)
  end
end
