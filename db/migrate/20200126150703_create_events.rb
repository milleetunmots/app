class CreateEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :events do |t|
      t.string :type, index: true

      t.belongs_to :related, polymorphic: true
      t.datetime :occurred_at

      t.text :body

      t.timestamps
    end
  end
end
