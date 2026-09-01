require 'rails_helper'

RSpec.describe BlockedSendAttempt::PhoneNumberSendGuard do
  let(:premium_number) { '0890123456' }

  describe '#blocked_phone_numbers' do
    it 'retient un numéro surtaxé' do
      guard = described_class.new("Appelez le #{premium_number} pour vos livres", provider: 'spothit')

      expect(guard.blocked_phone_numbers).to eq([premium_number])
    end

    # Whitelist stricte : le type du numéro n'entre pas en jeu, seule compte son
    # absence de la liste des numéros autorisés.
    it 'retient un mobile non autorisé' do
      guard = described_class.new('Son numéro est le 07 55 80 00 00', provider: 'spothit')

      expect(guard.blocked_phone_numbers).to eq(['0755800000'])
    end

    it 'retient un fixe non autorisé' do
      guard = described_class.new('Le centre est au 01 70 12 34 56', provider: 'spothit')

      expect(guard.blocked_phone_numbers).to eq(['0170123456'])
    end

    it 'retient un numéro vert non autorisé' do
      guard = described_class.new('Appelez gratuitement le 0800 12 34 56', provider: 'spothit')

      expect(guard.blocked_phone_numbers).to eq(['0800123456'])
    end

    it "renvoie un tableau vide quand le texte ne contient aucun numéro" do
      guard = described_class.new('Bonjour, ceci est un message sans numéro.', provider: 'spothit')

      expect(guard.blocked_phone_numbers).to eq([])
    end

    it 'canonicalise toutes les notations en une seule valeur détectée' do
      guard = described_class.new(
        "Appelez #{premium_number} ou 08.90.12.34.56 ou +33 8 90 12 34 56 ou 0033890123456",
        provider: 'spothit'
      )

      expect(guard.blocked_phone_numbers).to eq([premium_number])
    end

    it 'couvre toute la tranche surtaxée' do
      guard = described_class.new('0890000000 et 0899999999', provider: 'spothit')

      expect(guard.blocked_phone_numbers).to contain_exactly('0890000000', '0899999999')
    end

    # Non-régression du besoin d'origine : toutes les tranches à valeur ajoutée
    # (numéros gris, coût partagé, surtaxés) restent couvertes.
    it 'couvre les tranches à valeur ajoutée' do
      %w[0806123456 0809123456 0810123456 0825123456 0812345678].each do |number|
        guard = described_class.new("Appelez le #{number}", provider: 'spothit')

        expect(guard.blocked_phone_numbers).to eq([number]), "numéro non retenu : #{number}"
      end
    end

    # Le périmètre s'arrête aux numéros à 10 chiffres : les numéros courts ne
    # sont pas scannés, qu'ils soient surtaxés (118 712) ou gratuits (3919).
    it 'ne scanne pas les numéros courts' do
      guard = described_class.new('Appelez le 118 712, le 3919 ou le 3020', provider: 'spothit')

      expect(guard.blocked_phone_numbers).to eq([])
    end

    it 'scanne aussi les extra_texts (variables destinataires SpotHit)' do
      guard = described_class.new('Rappelez votre accompagnante au {NUMERO}', provider: 'spothit', extra_texts: [premium_number])

      expect(guard.blocked_phone_numbers).to eq([premium_number])
    end

    # Depuis que le type du numéro n'est plus contrôlé, seuls les lookarounds de
    # NATIONAL_PHONE_REGEX écartent ces séquences. Token hex figé : tiré au sort,
    # il finit par contenir 10 chiffres d'affilée et rend l'exemple instable.
    context 'faux positifs' do
      it "ne confond pas un numéro avec une suite de chiffres plus longue ni avec une date" do
        [
          'EAN 9782070612758 du livre',
          'Rendez-vous le 04.09.2026 à 10h',
          '35 rue des Lilas 75012 Paris',
          'Voici votre token 9f3a1c7e4b8d2056af13c9e7b4d0a682'
        ].each do |text|
          guard = described_class.new(text, provider: 'spothit')

          expect(guard.blocked_phone_numbers).to eq([]), "faux positif pour : #{text.inspect}"
        end
      end
    end

    context 'avec une whitelist' do
      it "ne retient pas un numéro surtaxé explicitement autorisé (asso, centre)" do
        FactoryBot.create(:allowed_pattern, kind: 'phone_number', match_type: 'exact', value: '0810123456')
        guard = described_class.new('Le centre est joignable au 0810 12 34 56', provider: 'spothit')

        expect(guard.blocked_phone_numbers).to eq([])
      end

      it "autorise le numéro Aircall d'une accompagnante sans aucune saisie" do
        FactoryBot.create(:admin_user, aircall_phone_number: '+33810123456')
        guard = described_class.new('Enregistrez son numéro : 0810 12 34 56', provider: 'spothit')

        expect(guard.blocked_phone_numbers).to eq([])
      end

      # Un envoi de masse produit un candidat par destinataire : les numéros
      # autorisés doivent être chargés une fois, pas une fois par numéro.
      it 'ne charge les numéros autorisés qu\'une seule fois' do
        guard = described_class.new('0890123456, 0899999999 et 0810123456', provider: 'spothit')

        expect(AllowedPattern).to receive(:allowed_phone_numbers).once.and_call_original

        expect(guard.blocked_phone_numbers.size).to eq(3)
      end
    end
  end

  describe '#blocked?' do
    it 'est true quand un numéro surtaxé est présent' do
      guard = described_class.new(premium_number, provider: 'spothit')

      expect(guard.blocked?).to be(true)
    end

    it "est false quand aucun numéro n'est présent" do
      guard = described_class.new('Bonjour, ceci est un message sans numéro.', provider: 'spothit')

      expect(guard.blocked?).to be(false)
    end
  end

  describe '#block_send?' do
    around do |example|
      previous = ENV['PHONE_NUMBER_FILTER_BLOCKING_ENABLED']
      example.run
      ENV['PHONE_NUMBER_FILTER_BLOCKING_ENABLED'] = previous
    end

    it "est false quand PHONE_NUMBER_FILTER_BLOCKING_ENABLED n'est pas défini (mode surveillance)" do
      ENV.delete('PHONE_NUMBER_FILTER_BLOCKING_ENABLED')
      guard = described_class.new(premium_number, provider: 'spothit')

      expect(guard.block_send?).to be(false)
    end

    it 'est true quand le flag est défini et un numéro surtaxé est présent' do
      ENV['PHONE_NUMBER_FILTER_BLOCKING_ENABLED'] = 'true'
      guard = described_class.new(premium_number, provider: 'spothit')

      expect(guard.block_send?).to be(true)
    end

    it "est false quand le flag est défini mais qu'aucun numéro n'est bloqué" do
      ENV['PHONE_NUMBER_FILTER_BLOCKING_ENABLED'] = 'true'
      guard = described_class.new('Bonjour, ceci est un message sans numéro.', provider: 'spothit')

      expect(guard.block_send?).to be(false)
    end
  end

  describe '#register!' do
    around do |example|
      previous = ENV['PHONE_NUMBER_FILTER_BLOCKING_ENABLED']
      example.run
      ENV['PHONE_NUMBER_FILTER_BLOCKING_ENABLED'] = previous
    end

    it 'crée un unique BlockedSendAttempt regroupant tous les numéros bloqués du message' do
      ENV['PHONE_NUMBER_FILTER_BLOCKING_ENABLED'] = 'true'
      guard = described_class.new(
        "Appelez le #{premium_number} ou le 0899 99 99 99",
        provider: 'aircall',
        replay_params: { message: premium_number }
      )

      expect { guard.register! }.to change(BlockedSendAttempt, :count).by(1)

      attempt = BlockedSendAttempt.last
      expect(attempt.provider).to eq('aircall')
      expect(attempt.kind).to eq('phone_number')
      expect(attempt.detected_values).to contain_exactly(premium_number, '0899999999')
      expect(attempt.status).to eq('pending')
    end

    it "crée le BlockedSendAttempt en not_blocked quand le flag n'est pas défini" do
      ENV.delete('PHONE_NUMBER_FILTER_BLOCKING_ENABLED')
      guard = described_class.new(premium_number, provider: 'aircall')

      guard.register!

      expect(BlockedSendAttempt.last.status).to eq('not_blocked')
    end

    it 'ne crée aucun BlockedSendAttempt quand blocked_send_attempt_id est déjà fourni (relance)' do
      existing = FactoryBot.create(:blocked_send_attempt)
      guard = described_class.new(premium_number, provider: 'spothit', blocked_send_attempt_id: existing.id)

      expect { guard.register! }.not_to change(BlockedSendAttempt, :count)
    end
  end
end
