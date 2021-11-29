class CreateWorkshops < ActiveRecord::Migration[6.0]
  def change
    create_table :workshops do |t|
      t.string :title
      t.string :co_animator
      t.datetime :occurred_at
      t.string :address, null: false
      t.string :postal_code, null: false
      t.string :city_name, null: false
      t.text :description
      t.references :animator, foreign_key: {to_table: :admin_users}

      t.timestamps
    end

    add_reference :events, :workshop
  end
end
