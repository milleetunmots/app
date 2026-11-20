require 'rails_helper'

RSpec.describe 'Admin vérification d’adresse pour le livre partenaire', type: :request do
  def partner_book_bundle
    FactoryBot.create(:media_text_messages_bundle, name: "Vérification de l'adresse pour le livre offert par un partenaire",
                                                   body1: 'Livre pour {PRENOM_ENFANT} à : {PARENT_ADDRESS}', body2: nil, body3: nil)
              .tap { |bundle| bundle.update_column(:key, 'verification_adresse_livre_partenaire') }
  end

  def send_address_verification(saturated: false)
    claire = FactoryBot.create(:admin_user, user_role: 'contributor', name: 'Claire')
    FactoryBot.create(:sms_send_record, admin_user: claire, recipients_count: 50) if saturated
    sign_in claire
    post '/admin/children/batch_action', params: {
      batch_action: 'send_address_verification_message', collection_selection: [FactoryBot.create(:child, first_name: 'Léa').id]
    }
  end

  it 'affiche « Messages envoyés » quand le trio existe' do
    partner_book_bundle

    send_address_verification

    expect(flash[:notice]).to eq('Messages envoyés')
  end

  it 'affiche le trio introuvable quand il manque' do
    allow(Rollbar).to receive(:error)

    send_address_verification

    expect(flash[:alert]).to include(
      "Trio introuvable : « Vérification de l'adresse pour le livre offert par un partenaire » (clé verification_adresse_livre_partenaire), message non envoyé"
    )
  end

  it 'affiche le message de quota quand le quota est atteint et le trio introuvable' do
    send_address_verification(saturated: true)

    expect(flash[:alert]).to include(SmsSendRecord::QuotaGuard::QUOTA_EXCEEDED_MESSAGE)
  end
end
