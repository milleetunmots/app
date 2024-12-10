class ChangeAddressSuspectedInvalidFromChildSupports < ActiveRecord::Migration[6.1]
  def up
    rename_column :child_supports, :is_address_suspected_invalid, :address_suspected_invalid_at
    change_column_null :child_supports, :address_suspected_invalid_at, true
    change_column_default :child_supports, :address_suspected_invalid_at, from: false, to: nil
    change_column :child_supports, :address_suspected_invalid_at, :datetime, using: "NULL"
  end

  def down
    change_column_null :child_supports, :address_suspected_invalid_at, true
    change_column :child_supports, :address_suspected_invalid_at, :boolean, default: false, null: false, using: "false"
    rename_column :child_supports, :address_suspected_invalid_at, :is_address_suspected_invalid
  end
end
