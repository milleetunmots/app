class RemoveNotNullConstraintOnChildGender < ActiveRecord::Migration[6.0]
  def change
    change_column_null :children, :gender, true
  end
end
