class ChangeIsBilingualToBeStringInChildSupports < ActiveRecord::Migration[6.1]
  def up
    add_column :child_supports, :is_bilingual_string, :string, default: '2_no_information'

    ChildSupport.reset_column_information
    ChildSupport.where(is_bilingual: true).update_all(is_bilingual_string: '0_yes')
    ChildSupport.where(is_bilingual: false).update_all(is_bilingual_string: '2_no_information')
    ChildSupport.where(is_bilingual: nil).update_all(is_bilingual_string: '2_no_information')

    remove_column :child_supports, :is_bilingual
    rename_column :child_supports, :is_bilingual_string, :is_bilingual
  end

  def down
    add_column :child_supports, :is_bilingual_boolean, :boolean

    ChildSupport.reset_column_information
    ChildSupport.where(is_bilingual: '0_yes').update_all(is_bilingual_boolean: true)
    ChildSupport.where(is_bilingual: '1_no').update_all(is_bilingual_boolean: false)
    ChildSupport.where(is_bilingual: '2_no_information').update_all(is_bilingual_boolean: nil)

    remove_column :child_supports, :is_bilingual
    rename_column :child_supports, :is_bilingual_boolean, :is_bilingual
  end
end
