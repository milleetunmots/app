class CreateBooks < ActiveRecord::Migration[6.1]
  def change
    create_table :books do |t|
      t.string :title, null: false
      t.string :ean, null: false

      t.timestamps
    end

    add_reference :support_modules, :book, foreign_key: true
    add_reference :books, :media, foreign_key: true

    add_index :books, :ean, unique: true
  end
end
