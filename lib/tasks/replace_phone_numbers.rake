namespace :db do
  desc 'Replace real phone numbers'
  task replace_phone_numbers: :environment do
    ChildSupport.where.not(other_phone_number: nil).update_all(other_phone_number: "+33#{ENV['FAKE_NUMBER']}")
    Parent.update_all(
      phone_number: "+33#{ENV['FAKE_NUMBER']}", 
      phone_number_national: "0#{ENV['FAKE_NUMBER']}",
      security_code: ENV['FAKE_SECURITY_CODE'])
  end
end
