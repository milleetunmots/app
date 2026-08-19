require 'rails_helper'

RSpec.describe SmsSendRecord, type: :model do
  let(:admin_user) { FactoryBot.create(:admin_user, user_role: 'contributor') }

  describe 'validations' do
    it 'est valide avec un nombre de destinataires positif' do
      expect(FactoryBot.build(:sms_send_record, admin_user: admin_user, recipients_count: 3)).to be_valid
    end

    it "n'est pas valide sans nombre de destinataires" do
      expect(FactoryBot.build(:sms_send_record, admin_user: admin_user, recipients_count: nil)).not_to be_valid
    end

    it "n'est pas valide avec zéro destinataire" do
      expect(FactoryBot.build(:sms_send_record, admin_user: admin_user, recipients_count: 0)).not_to be_valid
    end

    it "n'est pas valide avec un nombre de destinataires négatif" do
      expect(FactoryBot.build(:sms_send_record, admin_user: admin_user, recipients_count: -1)).not_to be_valid
    end

    it "n'est pas valide sans utilisateur" do
      expect(FactoryBot.build(:sms_send_record, admin_user: nil)).not_to be_valid
    end
  end

  describe '.since' do
    it 'inclut les envois à l’intérieur de la fenêtre' do
      record = FactoryBot.create(:sms_send_record, admin_user: admin_user, created_at: 59.minutes.ago)

      expect(described_class.since(1.hour)).to include(record)
    end

    it 'exclut les envois sortis de la fenêtre' do
      record = FactoryBot.create(:sms_send_record, admin_user: admin_user, created_at: 61.minutes.ago)

      expect(described_class.since(1.hour)).not_to include(record)
    end
  end
end
