class CreateBubbleModules < ActiveRecord::Migration[6.0]
  def change
    create_table :bubble_modules do |t|
      t.string :bubble_id, null: false
      t.text :description
      t.string :niveau
      t.string :theme
      t.string :titre
      t.date :created_date, null: false
    end
  end
end
