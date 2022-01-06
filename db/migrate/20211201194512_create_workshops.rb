class CreateWorkshops < ActiveRecord::Migration[6.0]
  def change
    create_table :workshops do |t|
      t.string :title, null: false
      t.string :co_animator
      t.datetime :occurred_at, null: false
      t.string :address, null: false
      t.string :postal_code, null: false
      t.string :city_name, null: false
      t.text :description
      t.text :invitation_message, null: false
      t.datetime :discarded_at

      t.timestamps
    end
  end
end
