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

      it "crée un enregistrement quand il bloque" do
        consume(50, 10.minutes.ago)

        expect { described_class.new(admin_user, 1).reserve! }.to change(SmsSendRecord, :count)
      end

      it 'bloque totalement un envoi qui ne dépasse que partiellement' do
        consume(48, 10.minutes.ago)

        expect(described_class.new(admin_user, 5).reserve!).to be(false)
        # La tentative est tracée mais en `blocked` : c'est le décompte hors
        # lignes bloquées, seul à alimenter le quota, qui ne doit pas bouger.
        expect(SmsSendRecord.not_blocked.sum(:recipients_count)).to eq(48)
        expect(SmsSendRecord.blocked.sum(:recipients_count)).to eq(5)
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
        expect(SmsSendRecord.not_blocked.since(1.hour).sum(:recipients_count)).to eq(50)
      end

      it 'prend un verrou sur la ligne de l’utilisatrice' do
        expect(AdminUser).to receive(:lock).and_call_original

        described_class.new(admin_user, 5).reserve!
      end
    end

    context 'alerte de blocage' do
      let(:slack) { instance_double(Slack::PostMessageService, errors: []) }
      let(:alerts) { [] }

      before do
        allow(slack).to receive(:call).and_return(slack)
        allow(Slack::PostMessageService).to receive(:new) do |payload|
          alerts << payload
          slack
        end
      end

      def alert_payload
        alerts.last
      end

      def alert_content
        alert_payload[:text]
      end

      it 'poste l’alerte dans le canal configuré' do
        consume(50, 10.minutes.ago)

        described_class.new(admin_user, 1).reserve!

        expect(alert_payload[:channel]).to eq("##{ENV['SLACK_QUOTA_ALERT_CHANNEL']}")
      end

      # L'emoji et le nom affiché sont ce qui rend l'alerte repérable dans le
      # canal, avant même d'en lire le contenu.
      it 'signe le message avec l’identité d’alerte' do
        consume(50, 10.minutes.ago)

        described_class.new(admin_user, 1).reserve!

        expect(alert_payload[:icon_emoji]).to eq(SmsSendRecord::QuotaGuard::ALERT_ICON_EMOJI)
        expect(alert_payload[:username]).to eq(SmsSendRecord::QuotaGuard::ALERT_USERNAME)
      end

      it 'alerte quand le plafond horaire bloque' do
        consume(50, 10.minutes.ago)

        described_class.new(admin_user, 1).reserve!

        expect(alert_content).to include('*Fenêtre(s) franchie(s)* : horaire')
      end

      it 'alerte quand seul le plafond journalier bloque' do
        consume(200, 5.hours.ago)

        described_class.new(admin_user, 1).reserve!

        expect(alert_content).to include('*Fenêtre(s) franchie(s)* : journalier')
      end

      it 'nomme les deux fenêtres quand les deux sont franchies' do
        consume(200, 10.minutes.ago)

        described_class.new(admin_user, 1).reserve!

        expect(alert_content).to include('*Fenêtre(s) franchie(s)* : horaire, journalier')
      end

      it 'identifie l’utilisatrice bloquée' do
        consume(50, 10.minutes.ago)

        described_class.new(admin_user, 1).reserve!

        expect(alert_content).to include("*Utilisatrice* : #{admin_user.name}")
      end

      it 'porte les compteurs de consommation et les plafonds' do
        consume(30, 10.minutes.ago)
        consume(120, 5.hours.ago)

        described_class.new(admin_user, 40).reserve!

        expect(alert_content).to include('*Destinataires demandés* : 40')
        expect(alert_content).to include('*Quota horaire* : 30 / 50')
        expect(alert_content).to include('*Quota journalier* : 150 / 200')
      end

      it 'annonce le blocage en première ligne' do
        consume(50, 10.minutes.ago)

        described_class.new(admin_user, 1).reserve!

        expect(alert_content.lines.first).to include('Envoi SMS bloqué')
      end

      it "n'alerte pas quand l'envoi passe" do
        consume(10, 30.minutes.ago)

        described_class.new(admin_user, 5).reserve!

        expect(Slack::PostMessageService).not_to have_received(:new)
      end

      it "n'alerte pas pour les périmètres exclus" do
        super_admin = FactoryBot.create(:admin_user, user_role: 'super_admin')
        consume(500, 10.minutes.ago, user: super_admin)

        described_class.new(nil, 500).reserve!
        described_class.new(super_admin, 100).reserve!

        expect(Slack::PostMessageService).not_to have_received(:new)
      end

      it "n'alerte pas pour un envoi sans destinataire" do
        consume(50, 10.minutes.ago)

        described_class.new(admin_user, 0).reserve!

        expect(Slack::PostMessageService).not_to have_received(:new)
      end

      # Slack indisponible ne doit pas changer l'issue de l'envoi : le blocage
      # reste un blocage, et la trace part dans Rollbar pour ne pas se perdre.
      it 'trace dans Rollbar quand Slack échoue, sans changer l’issue' do
        consume(50, 10.minutes.ago)
        allow(slack).to receive(:errors).and_return(['Slack chat.postMessage vers #test_app : channel_not_found'])

        expect(Rollbar).to receive(:error).with('Slack::PostMessageService', hash_including(:errors))

        expect(described_class.new(admin_user, 1).reserve!).to be(false)
      end

      # L'invariant qui justifie d'alerter après le commit : l'appel HTTP à Slack
      # est synchrone, l'émettre sous le SELECT … FOR UPDATE retiendrait le
      # verrou de la ligne admin_users pendant l'aller-retour. On compare des
      # profondeurs plutôt que d'attendre zéro, à cause de la transaction que
      # DatabaseCleaner ouvre autour de chaque exemple.
      it 'alerte hors de la transaction, pour ne pas retenir le verrou' do
        consume(50, 10.minutes.ago)
        depth_outside = ActiveRecord::Base.connection.open_transactions
        depth_at_alert = nil
        allow(slack).to receive(:call) do
          depth_at_alert = ActiveRecord::Base.connection.open_transactions
          slack
        end

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
