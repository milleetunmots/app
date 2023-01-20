class AddSupportModulesCountToGroups < ActiveRecord::Migration[6.0]
  def change
    add_column :groups, :support_modules_count, :integer, null: false, default: 0
  end
end
