class AddCanceledToWorkshops < ActiveRecord::Migration[6.0]
  def change
    add_column :workshops, :canceled, :boolean, null: false, default: false
  end
end
