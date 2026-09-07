module DbSanitizer
  class AdminSanitizer

    def call
      whitelist = ENV.fetch('ADMIN_USERS_ACCOUNTS_WHITELIST', '')
                     .split(',')
                     .map(&:strip)
                     .reject(&:empty?)

      # Les numéros 2FA sont des numéros personnels. Ils ne doivent jamais
      # survivre dans une copie de production sanitizée, y compris pour les
      # comptes explicitement conservés actifs sur l'environnement cible.
      AdminUser.update_all(
        phone_number: nil,
        two_factor_enabled: false,
        otp_code_digest: nil,
        otp_sent_at: nil,
        otp_attempts: 0,
        remember_created_at: nil
      )
      AdminUser.where.not(email: whitelist).update_all(is_disabled: true)
    end
  end
end
