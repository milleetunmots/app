class AddAdditionalMediumToSupportModuleWeeks < ActiveRecord::Migration[6.0]
  def change
    add_column :support_module_weeks, :additional_medium_id, :integer
    add_index :support_module_weeks, :additional_medium_id
    add_foreign_key :support_module_weeks,
                    :media,
                    column: :additional_medium_id
    add_column :support_module_weeks, :has_been_sent4, :boolean, null: false, default: false
  end
end
