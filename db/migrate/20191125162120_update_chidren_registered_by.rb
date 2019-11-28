class UpdateChidrenRegisteredBy < ActiveRecord::Migration[6.0]
  def change
    rename_column :children, :registered_by, :registration_source_details
    add_column :children, :registration_source, :string
  end
end
