class CreateSources < ActiveRecord::Migration[6.0]
  def change
    create_table :sources do |t|
      t.string :name, null: false, unique: true
      t.string :channel, null: false
      t.integer :department
      t.string :utm
      t.text :comment

      t.timestamps null: false
    end

    create_table :children_sources do |t|
      t.belongs_to :source
      t.belongs_to :child
      t.text :detail
      t.integer :registration_department

      t.timestamps null: false
    end
  end
end
