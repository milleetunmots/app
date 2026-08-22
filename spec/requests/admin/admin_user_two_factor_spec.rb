require 'rails_helper'

RSpec.describe 'Admin — activation du 2FA', type: :request do
  let(:super_admin) { FactoryBot.create(:admin_user, user_role: 'super_admin') }
  let(:contributor) { FactoryBot.create(:admin_user, user_role: 'contributor') }
  let(:target) { FactoryBot.create(:admin_user, user_role: 'caller') }

  describe 'super_admin' do
    before { sign_in super_admin }

    it 'peut renseigner le numéro et activer le 2FA' do
      put "/admin/admin_users/#{target.id}",
          params: { admin_user: { phone_number: '0612345678', two_factor_enabled: '1' } }

      target.reload
      expect(target.phone_number).to eq('+33612345678')
      expect(target.two_factor_enabled).to be(true)
    end

    it 'affiche la colonne 2FA sur l’index' do
      target.update!(phone_number: '0612345678', two_factor_enabled: true)
      get '/admin/admin_users'
      expect(response.body).to include('two_factor_enabled')
    end
  end

  describe 'utilisateur non super_admin' do
    before { sign_in contributor }

    it 'ne peut pas désactiver son propre 2FA' do
      contributor.update!(phone_number: '0612345678', two_factor_enabled: true)

      put "/admin/admin_users/#{contributor.id}",
          params: { admin_user: { two_factor_enabled: '0' } }

      expect(contributor.reload.two_factor_enabled).to be(true)
    end

    it 'ne peut pas modifier son propre numéro' do
      contributor.update!(phone_number: '0612345678', two_factor_enabled: true)

      put "/admin/admin_users/#{contributor.id}",
          params: { admin_user: { phone_number: '0799999999' } }

      expect(contributor.reload.phone_number).to eq('+33612345678')
    end
  end
end
