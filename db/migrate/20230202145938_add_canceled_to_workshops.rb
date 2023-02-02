class AddCanceledToWorkshops < ActiveRecord::Migration[6.0]
  def change
    add_column :workshops, :canceled, :boolean, null: false, default: false

    Workshop.update_all(canceled: false)
  end
end
