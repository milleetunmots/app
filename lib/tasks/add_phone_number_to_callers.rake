namespace :aircall do
  desc 'Replace real phone numbers and disable accounts not present in whitelist in staging'
  task add_phone_number_to_admin_users: :environment do
    users_service = Aircall::RetrieveUserService.new.call
    if users_service.errors.any?
      p users_service.errors
      return
    end

    users = users_service.users
    users.each do |user|
      user_id = user['id']
      name = user['name']
      email = user['email']
      user_service = Aircall::RetrieveUserService.new(user_id: user_id).call

      if user_service.errors.any?
        p user_id
        p user_service.errors
        p '------------------------------'
        next
      end

      aircall_user = user_service.users.first
      unless phone_number = aircall_user.try(:[], 'numbers')&.first.try(:[], 'digits')
        p user_id
        p 'No digits'
        p '------------------------------'
        next
      end

      admin_user = AdminUser.where('TRIM(LOWER(unaccent(name))) ILIKE TRIM(LOWER(unaccent(?))) OR TRIM(LOWER(unaccent(email))) ILIKE TRIM(LOWER(unaccent(?)))', name.squish, email).first
      unless admin_user
        p name
        p email
        p 'AdminUser not found'
        p '------------------------------'
        next
      end

      admin_user.update(aircall_phone_number: Phonelib.parse(phone_number).e164)
    end
  end
end
