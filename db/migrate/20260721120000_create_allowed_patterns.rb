class CreateAllowedPatterns < ActiveRecord::Migration[7.0]

  def change
    create_table :allowed_patterns do |t|
      t.string :kind, null: false
      t.string :match_type, null: false
      t.string :value, null: false

      t.timestamps
    end

    add_index :allowed_patterns, %i[kind match_type value], unique: true, name: 'index_allowed_patterns_on_kind_and_match_type_and_value'
  end
end
