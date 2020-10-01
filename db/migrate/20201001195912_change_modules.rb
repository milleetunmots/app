class ChangeModules < ActiveRecord::Migration[6.0]
  def change
    add_column :support_modules, :start_at, :date
    remove_column :support_module_weeks, :name
    add_column :support_module_weeks, :has_been_sent1, :boolean, null: false, default: false
    add_column :support_module_weeks, :has_been_sent2, :boolean, null: false, default: false
    add_column :support_module_weeks, :has_been_sent3, :boolean, null: false, default: false
  end
end
