class ChangeCalendlyColumnsOnAdminUsers < ActiveRecord::Migration[6.1]
  def up
    remove_column :admin_users, :calendly_scheduling_url, :string
    remove_column :admin_users, :calendly_event_type_uri, :string
    add_column :admin_users, :calendly_event_type_uris, :jsonb, default: {}
  end

  def down
    remove_column :admin_users, :calendly_event_type_uris, :jsonb
    add_column :admin_users, :calendly_event_type_uri, :string
    add_column :admin_users, :calendly_scheduling_url, :string
  end
end
