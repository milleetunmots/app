class CreateCallSessionDateOverrides < ActiveRecord::Migration[7.0]
  def change
    create_table :call_session_date_overrides do |t|
      t.references :admin_user, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.integer :call_session, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false

      t.timestamps
    end

    add_index :call_session_date_overrides,
              %i[admin_user_id group_id call_session],
              unique: true,
              name: 'index_call_session_date_overrides_on_trio'
  end
end
