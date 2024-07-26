namespace :db do
  desc 'Replace real phone numbers'
  task update_data: :environment do
    tester_email = %w[sasha.mackiewicz@1001mots.org lucas.augustin@1001mots.org mathieu.rumeau@1001mots.org antoine.marechal@1001mots.org alexandre.viguier@1001mots.org celine.david@1001mots.org camille.bellier@1001mots.org marion.turbet@1001mots.org pro@maxmartin.fr aristide.bamenou@1001mots.org]
    ChildSupport.update_all(other_phone_number: '+33800000000')
    Parent.update_all(phone_number: '+33800000000', phone_number_national: '+33800000000')
    AdminUser.where.not(email: tester_email).update_all(is_disabled: true)
  end
end
