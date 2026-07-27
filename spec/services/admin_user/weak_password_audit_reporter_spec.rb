require 'rails_helper'

RSpec.describe AdminUser::WeakPasswordAuditReporter do
  let(:user) do
    FactoryBot.create(:admin_user, name: 'Jean Dupont', email: 'jdupont@1001mots.fr', user_role: 'caller')
  end
  let(:finding) { AdminUser::WeakPasswordAuditService::Finding.new(admin_user: user, category: 'ciblé:nom') }

  describe '.render' do
    subject(:report) { described_class.render(findings: [finding], total: 10) }

    it 'inclut email, rôle, catégorie et la synthèse' do
      expect(report).to include('jdupont@1001mots.fr')
      expect(report).to include('caller')
      expect(report).to include('ciblé:nom')
      expect(report).to include('1/10 comptes compromis')
    end

    it 'gère l\'absence de compte compromis' do
      empty = described_class.render(findings: [], total: 10)
      expect(empty).to include('0/10 comptes compromis')
    end
  end
end
