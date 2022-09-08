class AddAvailableForWorkshopsToChild < ActiveRecord::Migration[6.0]
  def change
    add_column :children, :available_for_workshops, :boolean, default: false
  end
end
