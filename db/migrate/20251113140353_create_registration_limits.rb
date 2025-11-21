class CreateRegistrationLimits < ActiveRecord::Migration[6.1]
  def change
    create_table :registration_limits do |t|
      t.belongs_to :source, null: false
      t.belongs_to :registration_link, null: false

      t.datetime :start_date, null: false
      t.datetime :end_date
      t.integer :limit, null: false
      t.string :registration_url_params

      t.boolean :is_archived, null: false, default: false

      t.timestamps
    end
  end
end
