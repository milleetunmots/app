class CreateParentsRegistrations < ActiveRecord::Migration[6.1]
  def change
    create_table :parents_registrations do |t|
      t.belongs_to :parent1, optional: true
      t.belongs_to :parent2, optional: true
      t.boolean :target_profile, null: false, default: true
      t.string :parent1_phone_number, null: false
      t.string :parent2_phone_number

      t.timestamps
    end
  end
end
