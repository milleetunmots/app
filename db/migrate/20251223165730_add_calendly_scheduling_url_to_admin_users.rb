class AddCalendlySchedulingUrlToAdminUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :admin_users, :calendly_scheduling_url, :string
  end
end
