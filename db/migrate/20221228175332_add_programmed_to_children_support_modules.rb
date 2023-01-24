class AddProgrammedToChildrenSupportModules < ActiveRecord::Migration[6.0]
  def change
    add_column :children_support_modules, :is_programmed, :boolean, null: false, default: false
  end
end
