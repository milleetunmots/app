class CreateAdminUserImpersonations < ActiveRecord::Migration[7.0]

  def change
    create_table :admin_user_impersonations do |t|
      t.references :operator, null: false, foreign_key: { to_table: :admin_users }
      t.references :target, null: false, foreign_key: { to_table: :admin_users }
      t.datetime :started_at, null: false
      t.datetime :ended_at

      t.timestamps
    end
  end
end
