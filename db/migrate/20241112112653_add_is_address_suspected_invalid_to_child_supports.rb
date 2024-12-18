class AddIsAddressSuspectedInvalidToChildSupports < ActiveRecord::Migration[6.1]
  def change
    add_column :child_supports, :is_address_suspected_invalid, :boolean, null: false, default: false
  end
end
