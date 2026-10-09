# Clés ActiveRecord Encryption, fournies par variables d'environnement.
#
# Générer un jeu de clés : `bin/rails db:encryption:init` (ou `SecureRandom.alphanumeric(32)` x 3).
#
# /!\ Une clé perdue rend définitivement illisibles les colonnes chiffrées
# (ex. child_supports.sensitive_information) : les conserver dans le gestionnaire de secrets.
#
# Rotation de la clé primaire : passer l'ancienne clé dans `previous` avant de changer
# `primary_key`, de façon à continuer à lire les anciennes valeurs, qui sont
# re-chiffrées avec la nouvelle clé à leur prochaine écriture :
#   ActiveRecord::Encryption.config.previous = [{ primary_key: ancienne_clé }]
# (voir https://guides.rubyonrails.org/active_record_encryption.html#rotating-keys)
if Rails.env.production? && !ENV['ASSETS_PRECOMPILE']
  %w[AR_ENCRYPTION_PRIMARY_KEY AR_ENCRYPTION_DETERMINISTIC_KEY AR_ENCRYPTION_KEY_DERIVATION_SALT].each do |name|
    ENV[name].presence || raise("Error: No #{name} provided")
  end
end

# Le railtie ActiveRecord configure le chiffrement AVANT config/initializers : positionner
# config.active_record.encryption ici serait donc sans effet, d'où l'appel direct.
ActiveRecord::Encryption.configure(
  primary_key: ENV.fetch('AR_ENCRYPTION_PRIMARY_KEY', nil),
  deterministic_key: ENV.fetch('AR_ENCRYPTION_DETERMINISTIC_KEY', nil),
  key_derivation_salt: ENV.fetch('AR_ENCRYPTION_KEY_DERIVATION_SALT', nil)
)
