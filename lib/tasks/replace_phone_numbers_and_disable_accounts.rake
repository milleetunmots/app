namespace :db do
  desc 'Replace real phone numbers and disable accounts not present in whitelist in staging'
  task replace_phone_numbers_and_disable_accounts: :environment do
    tester_emails = ENV['ADMIN_USERS_ACCOUNTS_WHITELIST'].split(',').collect(&:strip)
    ChildSupport.where.not(other_phone_number: nil).update_all(other_phone_number: "+33#{ENV['FAKE_NUMBER']}")
    Parent.update_all(
      phone_number: "+33#{ENV['FAKE_NUMBER']}", 
      phone_number_national: "0#{ENV['FAKE_NUMBER']}",
      security_code: ENV['FAKE_SECURITY_CODE'])
    AdminUser.where.not(email: tester_emails).update_all(is_disabled: true)
  end
end
