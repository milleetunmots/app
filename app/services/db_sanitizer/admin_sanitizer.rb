module DbSanitizer
  class AdminSanitizer
    def call
      whitelist = ENV.fetch('ADMIN_USERS_ACCOUNTS_WHITELIST', '')
                     .split(',')
                     .map(&:strip)
                     .reject(&:empty?)

      AdminUser.where.not(email: whitelist).update_all(is_disabled: true)
    end
  end
end
