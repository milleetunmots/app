# == Schema Information
#
# Table name: admin_users
#
#  id                         :bigint           not null, primary key
#  aircall_phone_number       :string
#  automatic_sms_activated_at :datetime
#  calendly_event_type_uris   :jsonb
#  calendly_user_uri          :string
#  can_export_data            :boolean          default(FALSE), not null
#  can_send_automatic_sms     :boolean          default(TRUE), not null
#  can_treat_task             :boolean          default(FALSE), not null
#  current_sign_in_at         :datetime
#  current_sign_in_ip         :inet
#  email                      :string           default(""), not null
#  encrypted_password         :string           default(""), not null
#  group_subscriptions        :jsonb            not null
#  is_disabled                :boolean          default(FALSE)
#  last_sign_in_at            :datetime
#  last_sign_in_ip            :inet
#  name                       :string
#  otp_attempts               :integer          default(0), not null
#  otp_code_digest            :string
#  otp_sent_at                :datetime
#  phone_number               :string
#  remember_created_at        :datetime
#  reset_password_sent_at     :datetime
#  reset_password_token       :string
#  sign_in_count              :integer          default(0), not null
#  two_factor_enabled         :boolean          default(FALSE), not null
#  user_role                  :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  aircall_number_id          :bigint
#
# Indexes
#
#  index_admin_users_on_email                 (email) UNIQUE
#  index_admin_users_on_reset_password_token  (reset_password_token) UNIQUE
#

require "rails_helper"

RSpec.describe AdminUser, type: :model do
  subject { FactoryBot.create(:admin_user) }

  describe "Validations" do
    let(:valid_user) { FactoryBot.build(:admin_user, password: 'test22398@') }

    context "succeed" do
      it "if the password is valid" do
        expect(valid_user).to be_valid
      end
    end

    context "fail" do
      let(:invalid_user) { FactoryBot.build(:admin_user) }

      it "if the password haven't special characters" do
        invalid_user.password = 'test22398'
        expect(invalid_user).to_not be_valid
      end

      it "if the password haven't 8 characters at least" do
        invalid_user.password = 'te98'
        expect(invalid_user).to_not be_valid
      end

      it "if the password haven't a numeric character" do
        invalid_user.password = 'testspecs'
        expect(invalid_user).to_not be_valid
      end

      it "if the password include common password" do
        invalid_user.password = 'testspecs1001'
        expect(invalid_user).to_not be_valid
      end
    end
  end

  describe "#name" do
    let(:another_user) { FactoryBot.build(:admin_user, name: subject.name) }

    it "is required" do
      subject.name = nil

      expect(subject).to_not be_valid
    end

    it "is unique" do
      expect(another_user).to_not be_valid
    end
  end

  describe "#user_role" do
    it "is required" do
      subject.user_role = nil

      expect(subject).to_not be_valid
    end

    it "is included in ROLES" do
      subject.user_role = "thinker"

      expect(subject).to_not be_valid
    end
  end

  describe "#admin?" do
    it "return true if user is a super_admin" do
      expect(subject.admin?).to be subject.user_role == "super_admin"
    end
  end

  describe "#contributor?" do
    it "return true if user is a contributor" do
      expect(subject.contributor?).to be subject.user_role == "contributor"
    end
  end

  describe "#reader?" do
    it "return true if user is a reader" do
      expect(subject.reader?).to be subject.user_role == "reader"
    end
  end

  describe "#caller?" do
    it "return true if user is a caller" do
      expect(subject.caller?).to be subject.user_role == "caller"
    end
  end

  describe "#animator?" do
    it "return true if user is an animator" do
      expect(subject.animator?).to be subject.user_role == "animator"
    end
  end

  describe 'automatic_sms_activated_at tracking' do
    subject { FactoryBot.create(:admin_user, can_send_automatic_sms: false) }

    it 'records the activation time when can_send_automatic_sms turns on' do
      subject.update!(can_send_automatic_sms: true)
      expect(subject.automatic_sms_activated_at).to be_within(2.seconds).of(Time.zone.now)
    end

    it 'keeps the previous activation time when can_send_automatic_sms turns off' do
      subject.update!(can_send_automatic_sms: true)
      activated_at = subject.automatic_sms_activated_at

      subject.update!(can_send_automatic_sms: false)
      expect(subject.automatic_sms_activated_at).to eq(activated_at)
    end

    it 'keeps the previous activation time on an unrelated update' do
      subject.update!(can_send_automatic_sms: true)
      activated_at = subject.automatic_sms_activated_at

      subject.update!(name: 'New Name')
      expect(subject.automatic_sms_activated_at).to eq(activated_at)
    end
  end

  describe ".any_caller_or_animator_with_id?" do
    context 'when a caller with the given id exists' do
      it 'returns true' do
        subject.user_role = 'caller'
        subject.save
        expect(AdminUser.any_caller_or_animator_with_id?(subject.id)).to be_truthy
      end

      it 'returns true' do
        subject.user_role = 'animator'
        subject.save
        expect(AdminUser.any_caller_or_animator_with_id?(subject.id)).to be_truthy
      end
    end

    context 'when no caller with the given id exists' do
      let(:non_existent_id) { 10999 }

      it 'returns false' do
        expect(AdminUser.any_caller_or_animator_with_id?(non_existent_id)).to be_falsey
      end
    end
  end

  describe '.beta_test_supporters_who_cannot_send_automatic_sms' do
    # Le scope est évalué par ActiveAdmin au rendu de l'index des AdminUser :
    # une variable absente y ferait planter la page, pas seulement un service.
    it 'ne lève pas quand BETA_TEST_CALLERS_EMAIL n’est pas défini' do
      stub_const('ENV', ENV.to_h.except('BETA_TEST_CALLERS_EMAIL'))

      expect(described_class.beta_test_supporters_who_cannot_send_automatic_sms).to be_empty
    end
  end

  describe 'numéro de téléphone du 2FA' do
    it 'accepte un mobile français et le normalise en e164' do
      admin_user = FactoryBot.create(:admin_user, phone_number: '0612345678')
      expect(admin_user.reload.phone_number).to eq('+33612345678')
    end

    it 'refuse un numéro fixe' do
      admin_user = FactoryBot.build(:admin_user, phone_number: '0145678901')
      expect(admin_user).not_to be_valid
      expect(admin_user.errors[:phone_number]).to be_present
    end

    it 'accepte un numéro vide quand le 2FA est désactivé' do
      expect(FactoryBot.build(:admin_user, phone_number: nil, two_factor_enabled: false)).to be_valid
    end

    it 'exige un numéro quand le 2FA est activé' do
      admin_user = FactoryBot.build(:admin_user, phone_number: nil, two_factor_enabled: true)
      expect(admin_user).not_to be_valid
      expect(admin_user.errors[:phone_number]).to be_present
    end

    it 'a le 2FA désactivé par défaut' do
      expect(FactoryBot.create(:admin_user).two_factor_enabled).to be(false)
    end
  end

  describe 'activation du second facteur' do
    # Warden authentifie depuis le cookie « se souvenir de moi » sans jamais
    # repasser par le controller de sessions : un cookie posé avant l'activation
    # contournerait le second facteur jusqu'à deux semaines. Devise valide ces
    # cookies contre remember_created_at ; l'annuler les révoque tous.
    it 'révoque les cookies « se souvenir de moi » en cours' do
      admin_user = FactoryBot.create(:admin_user, phone_number: '0612345678')
      admin_user.update_columns(remember_created_at: 1.day.ago)

      admin_user.update!(two_factor_enabled: true)

      expect(admin_user.reload.remember_created_at).to be_nil
    end

    it 'ne touche pas à remember_created_at quand le flag ne change pas' do
      admin_user = FactoryBot.create(:admin_user, phone_number: '0612345678', two_factor_enabled: true)
      admin_user.update_columns(remember_created_at: 1.day.ago)

      admin_user.update!(name: 'Nouveau nom')

      expect(admin_user.reload.remember_created_at).to be_present
    end
  end

  describe 'code à usage unique' do
    let(:admin_user) { FactoryBot.create(:admin_user, phone_number: '0612345678', two_factor_enabled: true) }

    describe '#generate_otp!' do
      it 'retourne un code à 6 chiffres' do
        expect(admin_user.generate_otp!).to match(/\A\d{6}\z/)
      end

      it 'ne stocke jamais le code en clair' do
        code = admin_user.generate_otp!
        expect(admin_user.reload.otp_code_digest).to be_present
        expect(admin_user.otp_code_digest).not_to include(code)
      end

      it 'horodate l’envoi et remet le compteur de tentatives à zéro' do
        admin_user.update_columns(otp_attempts: 3)
        admin_user.generate_otp!
        expect(admin_user.reload.otp_sent_at).to be_within(5.seconds).of(Time.current)
        expect(admin_user.otp_attempts).to eq(0)
      end
    end

    describe '#verify_otp' do
      it 'retourne :no_code quand aucun code n’a été généré' do
        expect(admin_user.verify_otp('123456')).to eq(:no_code)
      end

      it 'retourne :ok pour le bon code et efface le code' do
        code = admin_user.generate_otp!
        expect(admin_user.verify_otp(code)).to eq(:ok)
        expect(admin_user.reload.otp_code_digest).to be_nil
      end

      it 'retourne :invalid pour un mauvais code et incrémente les tentatives' do
        admin_user.generate_otp!
        expect(admin_user.verify_otp('000000')).to eq(:invalid)
        expect(admin_user.reload.otp_attempts).to eq(1)
      end

      it 'retourne :expired au-delà de 10 minutes' do
        code = admin_user.generate_otp!
        travel_to(11.minutes.from_now) do
          expect(admin_user.verify_otp(code)).to eq(:expired)
        end
      end

      it 'retourne :too_many_attempts au 5e code faux, puis :no_code' do
        code = admin_user.generate_otp!
        4.times { expect(admin_user.verify_otp('000000')).to eq(:invalid) }
        expect(admin_user.verify_otp('000000')).to eq(:too_many_attempts)
        expect(admin_user.verify_otp(code)).to eq(:no_code)
      end

      # Chaque requête de vérification charge un objet neuf : si la décision se
      # prenait sur le compteur en mémoire (toujours 1 après un increment!),
      # N requêtes concurrentes offriraient N essais sur le même code.
      it 'décide à partir du compteur en base et non de sa copie en mémoire' do
        admin_user.generate_otp!
        AdminUser.where(id: admin_user.id).update_all(otp_attempts: AdminUser::OTP_MAX_ATTEMPTS - 1)

        expect(admin_user.verify_otp('000000')).to eq(:too_many_attempts)
      end

      it 'ne consomme un bon code qu’une fois sous deux requêtes concurrentes', js: true do
        code = admin_user.generate_otp!
        ready = Queue.new
        start = Queue.new

        threads = Array.new(2) do
          Thread.new do
            ActiveRecord::Base.connection_pool.with_connection do
              user = AdminUser.find(admin_user.id)
              ready << true
              start.pop
              user.verify_otp(code)
            end
          end
        end

        2.times { ready.pop }
        2.times { start << true }

        expect(threads.map(&:value)).to contain_exactly(:ok, :no_code)
      end
    end

    describe '#clear_otp!' do
      # otp_sent_at sert d'horloge de limitation des envois (1 par minute et par
      # compte) : l'effacer avec le code rendrait un renvoi immédiatement légal
      # juste après un blocage pour trop de tentatives.
      it 'efface le code sans remettre à zéro l’horloge des envois' do
        admin_user.generate_otp!

        admin_user.clear_otp!

        expect(admin_user.reload.otp_code_digest).to be_nil
        expect(admin_user.otp_attempts).to eq(0)
        expect(admin_user.otp_sent_at).to be_present
      end

      it 'laisse le renvoi interdit dans la minute qui suit un blocage' do
        admin_user.generate_otp!
        AdminUser::OTP_MAX_ATTEMPTS.times { admin_user.verify_otp('000000') }

        expect(admin_user.reload.otp_resendable?).to be(false)
      end
    end

    describe '#otp_resendable?' do
      it 'est vrai sans envoi précédent' do
        expect(admin_user.otp_resendable?).to be(true)
      end

      it 'est faux dans la minute qui suit un envoi' do
        admin_user.generate_otp!
        expect(admin_user.otp_resendable?).to be(false)
      end

      it 'est vrai une minute après l’envoi' do
        admin_user.generate_otp!
        travel_to(61.seconds.from_now) { expect(admin_user.otp_resendable?).to be(true) }
      end
    end

    describe '#masked_phone_number' do
      it 'ne laisse voir que les deux derniers chiffres' do
        expect(admin_user.masked_phone_number).to eq('•• •• •• •• 78')
      end
    end

    describe '#send_otp_by_sms' do
      it 'envoie un SMS contenant un code fraîchement généré' do
        admin_user.send_otp_by_sms

        expect(admin_user.reload.otp_code_digest).to be_present
        expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
          .with { |request| request.body.include?(CGI.escape('+33612345678')) }
      end

      it 'retourne le service, dont les erreurs sont consultables' do
        expect(admin_user.send_otp_by_sms.errors).to be_empty
      end
    end
  end
end
