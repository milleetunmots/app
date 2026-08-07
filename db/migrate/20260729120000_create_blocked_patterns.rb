class CreateBlockedPatterns < ActiveRecord::Migration[7.0]

  def change
    create_table :blocked_patterns do |t|
      t.string :kind, null: false
      t.string :value, null: false
      t.string :normalized_value, null: false
      t.timestamps
    end
    add_index :blocked_patterns, %i[kind normalized_value], unique: true
  end
end
