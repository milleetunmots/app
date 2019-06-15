class CreateChildren < ActiveRecord::Migration[6.0]
  def change
    create_table :children do |t|
      t.belongs_to :parent1, foreign_key: { to_table: :parents }, null: false
      t.belongs_to :parent2, foreign_key: { to_table: :parents }

      t.string :first_name, null: false
      t.string :last_name, null: false
      t.date :birthdate, null: false
      t.string :gender, null: false

      t.timestamps null: false
    end
  end
end
