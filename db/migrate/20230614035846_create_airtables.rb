class CreateAirtables < ActiveRecord::Migration[6.0]
  def change
    create_table :airtables do |t|
      t.string :type, index: true
      t.string :status
      t.string :siret_number

      t.belongs_to :admin_user, optional: true

      t.timestamps
    end
  end
end
