class NotNilForBilingual < ActiveRecord::Migration[6.0]
  def change
    change_column :support_modules, :for_bilingual, :boolean, null: false, default: false
  end
end
