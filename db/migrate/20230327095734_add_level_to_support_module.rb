class AddLevelToSupportModule < ActiveRecord::Migration[6.0]
  def change
    add_column :support_modules, :level, :integer
  end
end
