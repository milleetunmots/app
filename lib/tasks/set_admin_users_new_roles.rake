namespace :admin_users do
  desc 'Set new admin users roles'
  task set_new_roles: :environment do
    AdminUser.where(id: [154, 133, 63, 18, 144, 156, 160, 62, 141, 28, 162, 158, 68, 163]).update_all(user_role: 'reader')
    AdminUser.where(id: [105, 103, 92, 31, 136]).update_all(user_role: 'animator')
    AdminUser.where(id: [7, 140, 155, 157, 23, 142, 2, 159]).update_all(user_role: 'contributor')
    AdminUser.where(id: [32, 12, 45, 83, 117]).update_all(user_role: 'caller')
  end
end
