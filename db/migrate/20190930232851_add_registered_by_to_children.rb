class AddRegisteredByToChildren < ActiveRecord::Migration[6.0]
  def change
    add_column :children, :registered_by, :string
  end
end
