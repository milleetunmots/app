class CreateRegistrationLinks < ActiveRecord::Migration[6.1]
  def change
    create_table :registration_links do |t|
      t.string :url, null: false
      t.string :channel, null: false
      t.string :label, null: false

      t.timestamps
    end

    add_index :registration_links, :url, unique: true
    add_index :registration_links, :label, unique: true
  end
end
