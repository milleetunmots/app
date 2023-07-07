class CreateBubbleModules < ActiveRecord::Migration[6.0]
  def change
    create_table :bubble_modules do |t|
      t.text :description
      t.date :created_date, null: false
      t.integer :niveau
    end
  end
end
