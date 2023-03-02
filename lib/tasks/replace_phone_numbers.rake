namespace :db do
  desc 'Replace real phone numbers'
  task replace_phone_numbers: :environment do
    ChildSupport.update_all(other_phone_number: '+33800000000')
    Parent.update_all(phone_number: '+33800000000', phone_number_national: '+33800000000')
  end
end
