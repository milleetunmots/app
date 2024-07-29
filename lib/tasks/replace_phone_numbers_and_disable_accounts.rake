namespace :db do
  desc 'Replace real phone numbers and disable accounts not present in whitelist in staging'
  task replace_phone_numbers_and_disable_accounts: :environment do
    tester_emails = ENV['ADMIN_USERS_ACCOUNTS_WHITELIST'].split(',').collect(&:strip)
    ChildSupport.update_all(other_phone_number: '+33800000000')
    Parent.update_all(phone_number: '+33800000000', phone_number_national: '+33800000000')
    AdminUser.where.not(email: tester_emails).update_all(is_disabled: true)
  end
end
