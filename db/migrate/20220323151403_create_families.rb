class CreateFamilies < ActiveRecord::Migration[6.0]
  def change
    create_table :families do |t|
      t.belongs_to :parent1, foreign_key: { to_table: :parents }, null: false
      t.belongs_to :parent2, foreign_key: { to_table: :parents }
      t.belongs_to :child_support

      t.datetime :discarded_at

      t.timestamps
    end
  end
end
