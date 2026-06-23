class AddRcsErrorFieldsToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :rcs_error_code, :string
    add_column :events, :rcs_error_details, :string
  end
end