require 'rails_helper'

RSpec.describe 'Synchronisation des modèles Spot-Hit depuis ActiveAdmin', type: :request do
  before do
    sign_in FactoryBot.create(:admin_user, user_role: 'super_admin')
    allow(Media::SyncRcsModelsJob).to receive(:perform_later)
  end

  let(:bundle) { FactoryBot.create(:media_text_messages_bundle, name: 'Thème', body1: 'Bonjour !', body2: 'À demain !', body3: nil) }

  it 'lance la synchronisation des messages modifiés quand un trio est enregistré' do
    put "/admin/media_text_messages_bundles/#{bundle.id}",
        params: { media_text_messages_bundle: { name: 'Thème', body1: 'Bonjour !', body2: 'À ce soir !' } }

    expect(Media::SyncRcsModelsJob).to have_received(:perform_later).with(bundle.id, [2])
  end

  it 'lance la synchronisation de tous les messages du trio dupliqué' do
    get "/admin/media_text_messages_bundles/#{bundle.id}/duplicate"

    copy = Media::TextMessagesBundle.where.not(id: bundle.id).last
    expect(Media::SyncRcsModelsJob).to have_received(:perform_later).with(copy.id, [1, 2, 3])
  end

  it "lance la synchronisation de tous les messages d'un brouillon publié" do
    bundle.draft

    put "/admin/media_text_messages_bundle_drafts/#{bundle.id}/undraft"

    expect(Media::SyncRcsModelsJob).to have_received(:perform_later).with(bundle.id, [1, 2, 3])
  end

  it 'ne lance rien quand un trio est remis en brouillon' do
    put "/admin/media_text_messages_bundles/#{bundle.id}/draft", params: { task: { title: '' } }

    expect(Media::SyncRcsModelsJob).not_to have_received(:perform_later)
  end
end
