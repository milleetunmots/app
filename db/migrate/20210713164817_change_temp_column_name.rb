class ChangeTempColumnName < ActiveRecord::Migration[6.0]
  def change
    rename_column :child_supports, :temp, :books_quantity
  end
end
