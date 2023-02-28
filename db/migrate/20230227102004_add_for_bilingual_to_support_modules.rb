class AddForBilingualToSupportModules < ActiveRecord::Migration[6.0]
  def change
    add_column :support_modules, :for_bilingual, :boolean
  end
end
