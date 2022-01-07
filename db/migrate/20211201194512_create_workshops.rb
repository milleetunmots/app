class CreateWorkshops < ActiveRecord::Migration[6.0]
  def change
    create_table :workshops do |t|
      t.string :name, null: false
      t.string :co_animator
      t.date :workshop_date, null: false
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
