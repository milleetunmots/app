require 'rails_helper'

RSpec.describe SmsSendRecord::QuotaGuard, type: :service do
  let(:admin_user) { FactoryBot.create(:admin_user, user_role: 'contributor') }

  # Pose des envois déjà comptabilisés à un instant donné dans le passé.
  def consume(count, ago, user: admin_user)
    FactoryBot.create(:sms_send_record, admin_user: user, recipients_count: count, created_at: ago)
  end

  describe '#reserve!' do
    context 'périmètre exclu' do
      it "ne limite ni ne comptabilise les envois sans utilisateur à l'origine" do
        expect(described_class.new(nil, 500).reserve!).to be(true)
        expect(SmsSendRecord.count).to eq(0)
      end

      it "n'applique pas le plafond à un super_admin" do
        super_admin = FactoryBot.create(:admin_user, user_role: 'super_admin')
        consume(500, 10.minutes.ago, user: super_admin)

        expect(described_class.new(super_admin, 100).reserve!).to be(true)
      end

      it "ne comptabilise pas les envois d'un super_admin" do
        super_admin = FactoryBot.create(:admin_user, user_role: 'super_admin')

        expect { described_class.new(super_admin, 10).reserve! }.not_to change(SmsSendRecord, :count)
      end
    end

    context 'sous le plafond' do
      it 'réserve le quota et enregistre le nombre de destinataires' do
        consume(10, 30.minutes.ago)

        expect(described_class.new(admin_user, 5).reserve!).to be(true)
        expect(SmsSendRecord.order(:created_at).last.recipients_count).to eq(5)
      end

      it "horodate l'enregistrement à l'instant de la programmation" do
        described_class.new(admin_user, 5).reserve!

        expect(SmsSendRecord.last.created_at).to be_within(5.seconds).of(Time.zone.now)
      end

      it 'autorise un envoi atteignant exactement le plafond horaire' do
        consume(45, 10.minutes.ago)

        expect(described_class.new(admin_user, 5).reserve!).to be(true)
      end
    end

    context 'plafond horaire' do
      it 'bloque quand le plafond est atteint' do
        consume(50, 10.minutes.ago)

        expect(described_class.new(admin_user, 1).reserve!).to be(false)
      end

      it "ne crée aucun enregistrement quand il bloque" do
        consume(50, 10.minutes.ago)

        expect { described_class.new(admin_user, 1).reserve! }.not_to change(SmsSendRecord, :count)
      end

      it 'bloque totalement un envoi qui ne dépasse que partiellement' do
        consume(48, 10.minutes.ago)

        expect(described_class.new(admin_user, 5).reserve!).to be(false)
        expect(SmsSendRecord.sum(:recipients_count)).to eq(48)
      end

      it 'ne compte plus les envois sortis de la fenêtre horaire' do
        consume(45, 61.minutes.ago)
        consume(5, 10.minutes.ago)

        expect(described_class.new(admin_user, 40).reserve!).to be(true)
      end
    end

    context 'plafond journalier' do
      it 'bloque quand le plafond de 24 h est atteint alors que le plafond horaire est libre' do
        [2, 6, 10, 20].each { |hours| consume(50, hours.hours.ago) }

        expect(described_class.new(admin_user, 1).reserve!).to be(false)
      end

      it 'ne compte plus les envois sortis de la fenêtre de 24 h' do
        consume(200, 25.hours.ago)

        expect(described_class.new(admin_user, 10).reserve!).to be(true)
      end

      it 'ne se réinitialise pas à minuit' do
        # 200 destinataires programmés « hier soir », soit deux heures plus tôt
        # quand il est 00h30 : toujours dans la fenêtre glissante.
        consume(200, 2.hours.ago)

        expect(described_class.new(admin_user, 1).reserve!).to be(false)
      end
    end

    context 'entre utilisatrices' do
      it 'garde des compteurs indépendants' do
        other = FactoryBot.create(:admin_user, user_role: 'contributor')
        consume(50, 10.minutes.ago)

        expect(described_class.new(other, 5).reserve!).to be(true)
      end
    end

    context 'selon le rôle' do
      %w[contributor reader caller animator].each do |role|
        it "n'exempte pas le rôle #{role}" do
          user = FactoryBot.create(:admin_user, user_role: role)
          consume(50, 10.minutes.ago, user: user)

          expect(described_class.new(user, 1).reserve!).to be(false)
        end
      end
    end

    context 'avec des plafonds personnalisés' do
      it 'respecte les colonnes de l’utilisatrice' do
        admin_user.update!(sms_hourly_recipients_limit: 2, sms_daily_recipients_limit: 5)

        expect(described_class.new(admin_user, 2).reserve!).to be(true)
        expect(described_class.new(admin_user, 1).reserve!).to be(false)
      end
    end

    context 'concurrence' do
      # Deux guards construits AVANT toute réservation : c'est l'interleaving que
      # deux requêtes simultanées produiraient. Le parallélisme réel n'est pas
      # reproductible ici (transactions de test par exemple), mais le résultat
      # observable attendu par la spec l'est.
      it 'ne laisse passer qu’une seule des deux programmations' do
        consume(45, 10.minutes.ago)
        first = described_class.new(admin_user, 5)
        second = described_class.new(admin_user, 5)

        expect(first.reserve!).to be(true)
        expect(second.reserve!).to be(false)
        expect(SmsSendRecord.since(1.hour).sum(:recipients_count)).to eq(50)
      end

      it 'prend un verrou sur la ligne de l’utilisatrice' do
        expect(AdminUser).to receive(:lock).and_call_original

        described_class.new(admin_user, 5).reserve!
      end
    end

    context 'alerte de blocage' do
      # L'email est dans le libellé et non dans le payload : c'est ce qui fait
      # créer à Rollbar un item par utilisatrice, donc une notification Slack
      # dès qu'une nouvelle personne atteint son plafond.
      let(:label) { "SmsSendRecord::QuotaGuard : envoi bloqué — #{admin_user.email}" }

      it 'alerte quand le plafond horaire bloque' do
        consume(50, 10.minutes.ago)

        expect(Rollbar).to receive(:warning).with(label, hash_including(exceeded_windows: ['horaire']))

        described_class.new(admin_user, 1).reserve!
      end

      it 'alerte quand seul le plafond journalier bloque' do
        consume(200, 5.hours.ago)

        expect(Rollbar).to receive(:warning).with(label, hash_including(exceeded_windows: ['journalier']))

        described_class.new(admin_user, 1).reserve!
      end

      it 'nomme les deux fenêtres quand les deux sont franchies' do
        consume(200, 10.minutes.ago)

        expect(Rollbar).to receive(:warning).with(label, hash_including(exceeded_windows: %w[horaire journalier]))

        described_class.new(admin_user, 1).reserve!
      end

      it 'porte les compteurs de consommation et les plafonds' do
        consume(30, 10.minutes.ago)
        consume(120, 5.hours.ago)

        expect(Rollbar).to receive(:warning).with(
          label,
          hash_including(
            admin_user_id: admin_user.id,
            recipients_count: 40,
            consumed_hourly: 30,
            consumed_daily: 150,
            hourly_limit: 50,
            daily_limit: 200
          )
        )

        described_class.new(admin_user, 40).reserve!
      end

      it "n'alerte pas quand l'envoi passe" do
        consume(10, 30.minutes.ago)

        expect(Rollbar).not_to receive(:warning)

        described_class.new(admin_user, 5).reserve!
      end

      it "n'alerte pas pour les périmètres exclus" do
        super_admin = FactoryBot.create(:admin_user, user_role: 'super_admin')
        consume(500, 10.minutes.ago, user: super_admin)

        expect(Rollbar).not_to receive(:warning)

        described_class.new(nil, 500).reserve!
        described_class.new(super_admin, 100).reserve!
      end

      it "n'alerte pas pour un envoi sans destinataire" do
        consume(50, 10.minutes.ago)

        expect(Rollbar).not_to receive(:warning)

        described_class.new(admin_user, 0).reserve!
      end

      # L'invariant qui justifie d'alerter après le commit : `Rollbar.warning`
      # est synchrone, l'appeler sous le SELECT … FOR UPDATE retiendrait le
      # verrou de la ligne admin_users pendant l'aller-retour HTTP. On compare
      # des profondeurs plutôt que d'attendre zéro, à cause de la transaction
      # que DatabaseCleaner ouvre autour de chaque exemple.
      it 'alerte hors de la transaction, pour ne pas retenir le verrou' do
        consume(50, 10.minutes.ago)
        depth_outside = ActiveRecord::Base.connection.open_transactions
        depth_at_alert = nil
        allow(Rollbar).to receive(:warning) { depth_at_alert = ActiveRecord::Base.connection.open_transactions }

        described_class.new(admin_user, 1).reserve!

        expect(depth_at_alert).to eq(depth_outside)
      end
    end
  end

  describe '#mark_blocked!' do
    it 'marque la réservation sans supprimer la trace de la tentative' do
      guard = described_class.new(admin_user, 5)
      guard.reserve!

      expect { guard.mark_blocked! }.not_to change(SmsSendRecord, :count)
      expect(SmsSendRecord.last).to be_blocked
    end

    it 'rend le quota réservé' do
      guard = described_class.new(admin_user, 50)
      guard.reserve!
      guard.mark_blocked!

      expect(described_class.new(admin_user, 50).reserve!).to be(true)
    end

    it 'est idempotent' do
      guard = described_class.new(admin_user, 5)
      guard.reserve!
      guard.mark_blocked!

      expect { guard.mark_blocked! }.not_to(change { SmsSendRecord.last.updated_at })
    end

    it 'ne fait rien quand rien n’a été réservé' do
      guard = described_class.new(admin_user, 5)

      expect { guard.mark_blocked! }.not_to change(SmsSendRecord, :count)
    end
  end

  describe '#error_message' do
    it 'expose le message affiché à l’utilisatrice' do
      expect(described_class.new(admin_user, 1).error_message)
        .to eq("Vous avez atteint la limite d'envoi de messages. Aucun message n'a pu être envoyé. Contactez un admin.")
    end
  end
end
