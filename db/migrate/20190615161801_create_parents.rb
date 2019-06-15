class CreateParents < ActiveRecord::Migration[6.0]
  def change
    create_table :parents do |t|
      t.string :gender, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :phone_number, null: false
      t.string :email, null: false
      t.string :address, null: false
      t.string :postal_code, null: false
      t.string :city_name, null: false

      t.timestamps null: false
    end
  end
end
