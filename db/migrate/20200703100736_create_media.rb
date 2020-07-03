class CreateMedia < ActiveRecord::Migration[6.0]
  def change
    create_table :media do |t|
      t.string :type, index: true

      t.string :name

      t.string :url

      t.text :body1
      t.text :body2
      t.text :body3

      t.datetime :discarded_at, index: true

      t.timestamps
    end
  end
end
