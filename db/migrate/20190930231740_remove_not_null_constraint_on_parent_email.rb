class RemoveNotNullConstraintOnParentEmail < ActiveRecord::Migration[6.0]
  def change
    change_column :parents, :email, :string, null: true
  end
end
