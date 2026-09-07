require 'rails_helper'

RSpec.describe 'Admin sms send records', type: :request do
  let(:sms_send_record) { FactoryBot.create(:sms_send_record) }

  describe "en tant qu'admin habilité (super_admin)" do
    before { sign_in FactoryBot.create(:admin_user, user_role: 'super_admin') }

    it 'peut consulter la liste des envois comptabilisés' do
      get '/admin/sms_send_records'
      expect(response).to have_http_status(:ok)
    end

    # Cible du lien porté par l'alerte Slack de dépassement de quota
    # (cf. SmsSendRecord::QuotaGuard#blocked_record_line).
    it "peut consulter le détail d'un envoi" do
      get "/admin/sms_send_records/#{sms_send_record.id}"
      expect(response).to have_http_status(:ok)
    end
  end

  %w[contributor reader caller animator].each do |role|
    describe "en tant que #{role}" do
      before { sign_in FactoryBot.create(:admin_user, user_role: role) }

      it "n'a pas accès au détail d'un envoi" do
        get "/admin/sms_send_records/#{sms_send_record.id}"
        expect(response).to redirect_to('/admin/children')
      end
    end
  end
end
