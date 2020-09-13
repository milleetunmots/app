class CreateModules < ActiveRecord::Migration[6.0]
  def change
    create_table :support_modules do |t|
      t.string :name
      t.string :ages, null: false
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :support_modules, :discarded_at

    create_table :support_module_weeks do |t|
      t.belongs_to :support_module, null: false
      t.belongs_to :medium
      t.string :name
      t.integer :position, null: false, default: 0
    end
    add_index :support_module_weeks, :position
  end
end
