class FixVersionsTableStructure < ActiveRecord::Migration[7.0]
  def up
    # First remove the incorrect column that includes the curly braces
    execute 'ALTER TABLE versions DROP COLUMN IF EXISTS "{null: false}"'
    
    # Then ensure item_type is not null
    change_column :versions, :item_type, :string, null: false
  end

  def down
    change_column :versions, :item_type, :string, null: true
  end
end
