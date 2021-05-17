class RemoveAgesFromSupportModules < ActiveRecord::Migration[6.0]
  def change
    remove_column :support_modules, :ages, :string
  end
end
