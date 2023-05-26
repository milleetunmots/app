class NotNilForBilingual < ActiveRecord::Migration[6.0]
  def change
    SupportModule.where(for_bilingual: nil).update_all(for_bilingual: false)

    change_column :support_modules, :for_bilingual, :boolean, null: false, default: false
  end
end
