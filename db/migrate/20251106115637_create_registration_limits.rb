class CreateRegistrationLimits < ActiveRecord::Migration[6.1]
  def change
    create_table :registration_limits do |t|
      t.belongs_to :source, null: false

      t.date :start_date, null: false
      t.date :end_date
      t.integer :limit, null: false
      t.string :registration_form, null: false
      t.string :registration_url_params

      t.boolean :is_archived, null: false, default: false

      t.timestamps
    end
  end
end
