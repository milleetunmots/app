class AddCalendlyEventTypeUriToAdminUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :admin_users, :calendly_event_type_uri, :string
  end
end
