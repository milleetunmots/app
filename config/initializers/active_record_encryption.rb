# Clés ActiveRecord Encryption, fournies par variables d'environnement.
#
# Générer un jeu de clés : `bin/rails db:encryption:init` (ou `SecureRandom.alphanumeric(32)` x 3).
#
# /!\ Une clé perdue rend définitivement illisibles les colonnes chiffrées
# (ex. child_supports.sensitive_information) : les conserver dans le gestionnaire de secrets.
#
# Rotation de la clé primaire : `primary_key` accepte une LISTE de clés. La dernière chiffre, toutes
# déchiffrent ; les anciennes valeurs sont re-chiffrées avec la nouvelle clé à leur prochaine écriture.
# Ne PAS utiliser `config.previous` pour cela : il décrit d'anciens schémas de chiffrement
# (`{ key_provider: ... }`), pas des clés. Cette initialisation lit aujourd'hui une seule clé par variable :
# prévoir de la faire accepter une liste avant la première rotation, et la tester sur une copie de la base.
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
