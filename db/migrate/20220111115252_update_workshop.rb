class UpdateWorkshop < ActiveRecord::Migration[6.0]
  def change
    rename_column :workshops, :name, :topic
    change_column :workshops, :description, :string
    rename_column :workshops, :description, :name
  end
end
