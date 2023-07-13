class CreateBubbleContent < ActiveRecord::Migration[6.0]
  def change
    create_table :bubble_contents do |t|
      t.string :age, array: true
      t.index :age, using: 'gin'
      t.string :titre
      t.string :content_type
      t.integer :avis_nouveaute
      t.integer :avis_pas_adapte
      t.integer :avis_rappel
      t.text :description
      t.date :created_date, null: false
    end
  end
end
