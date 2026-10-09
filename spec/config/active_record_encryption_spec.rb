require 'rails_helper'

RSpec.describe 'Configuration du chiffrement ActiveRecord' do
  it 'chiffre puis déchiffre une valeur avec les clés configurées' do
    ciphertext = ActiveRecord::Encryption.encryptor.encrypt('Père sous mesure d éloignement')

    expect(ciphertext).not_to include('mesure')
    expect(ActiveRecord::Encryption.encryptor.decrypt(ciphertext)).to eq('Père sous mesure d éloignement')
  end

  it "lit les trois clés depuis l'environnement" do
    config = ActiveRecord::Encryption.config

    expect(config.primary_key).to eq(ENV.fetch('AR_ENCRYPTION_PRIMARY_KEY'))
    expect(config.deterministic_key).to eq(ENV.fetch('AR_ENCRYPTION_DETERMINISTIC_KEY'))
    expect(config.key_derivation_salt).to eq(ENV.fetch('AR_ENCRYPTION_KEY_DERIVATION_SALT'))
  end
end
