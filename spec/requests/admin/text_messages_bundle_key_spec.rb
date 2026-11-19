require 'rails_helper'

RSpec.describe "Clé d'un trio dans ActiveAdmin", type: :request do
  before { sign_in FactoryBot.create(:admin_user, user_role: 'super_admin') }

  def bundle_with_key
    bundle = FactoryBot.create(:media_text_messages_bundle, name: 'Fin du programme', body2: nil, body3: nil)
    bundle.update_column(:key, 'fin_programme')
    bundle
  end

  it 'affiche la clé sur la fiche du trio' do
    bundle = bundle_with_key

    get "/admin/media_text_messages_bundles/#{bundle.id}"

    key_row = Nokogiri::HTML(response.body).css('tr').find { |row| row.at_css('th')&.text&.strip == 'Clé' }
    expect(key_row.at_css('td').text.strip).to eq('fin_programme')
  end

  it "ne propose pas de champ pour la clé dans le formulaire d'édition" do
    bundle = bundle_with_key

    get "/admin/media_text_messages_bundles/#{bundle.id}/edit"

    expect(Nokogiri::HTML(response.body).at_css('[name="media_text_messages_bundle[key]"]')).to be_nil
  end

  it "ne modifie pas la clé quand une requête d'enregistrement en envoie une autre" do
    bundle = bundle_with_key

    put "/admin/media_text_messages_bundles/#{bundle.id}",
        params: { media_text_messages_bundle: { name: 'Fin du programme', body1: bundle.body1, key: 'autre_cle' } }

    expect(bundle.reload.key).to eq('fin_programme')
  end

  it 'ne recopie pas la clé quand le trio est dupliqué' do
    bundle = bundle_with_key

    get "/admin/media_text_messages_bundles/#{bundle.id}/duplicate"

    copy = Media::TextMessagesBundle.find_by(name: 'Copie de Fin du programme')
    expect(copy.key).to be_nil
    expect(bundle.reload.key).to eq('fin_programme')
  end
end
