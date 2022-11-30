class AddChoiceDateToChildrenSupportModule < ActiveRecord::Migration[6.0]
  def change
    add_column :children_support_modules, :choice_date, :date
  end
end
