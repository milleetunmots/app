require 'rails_helper'

RSpec.describe AdminUser::WeakPasswordAuditService do
  describe '#targeted_candidates (privé)' do
    let(:user) { FactoryBot.build(:admin_user, name: 'Jean Dupont', email: 'jdupont@1001mots.fr') }
    subject(:candidates) { described_class.new.send(:targeted_candidates, user) }

    it "dérive des candidats du nom, de l'email et de l'app avec leur catégorie" do
      values = candidates.map(&:first)
      expect(values).to include('Jeandupont2024')
      expect(values).to include('jdupont1234')
      expect(values).to include('1001mots!')
    end

    it 'étiquette chaque candidat avec sa catégorie' do
      categories = candidates.map(&:last).uniq
      expect(categories).to all(start_with('ciblé:'))
    end
  end

  describe '#call' do
    it 'détecte un compte dont le mot de passe correspond à un candidat ciblé' do
      user = FactoryBot.create(:admin_user, name: 'Marie Curie', email: 'mcurie@1001mots.fr', password: 'Mariecurie2024!')

      findings = described_class.new(scope: AdminUser.where(id: user.id), thread_count: 1).call

      expect(findings.map(&:admin_user)).to eq([user])
      expect(findings.first.category).to eq('ciblé:nom')
    end

    it 'ne détecte pas un compte au mot de passe fort/aléatoire' do
      FactoryBot.create(:admin_user, name: 'Marie Curie', email: 'mcurie@1001mots.fr', password: 'k9$Zx2!vQw-71bTp')

      findings = described_class.new(scope: AdminUser.all, thread_count: 1).call

      expect(findings).to be_empty
    end

    it 'appelle le callback de progression pour chaque compte' do
      FactoryBot.create(:admin_user)
      FactoryBot.create(:admin_user)
      seen = []
      progress = ->(done, total) { seen << [done, total] }

      described_class.new(scope: AdminUser.all, thread_count: 1, progress: progress).call

      expect(seen.last).to eq([2, 2])
    end
  end

  describe 'wordlist générique' do
    it 'détecte un compte dont le mot de passe est dans la wordlist fournie' do
      user = FactoryBot.create(:admin_user, password: 'AzrtQwer42!')
      wordlist = Tempfile.new('wl')
      wordlist.write("motdepassefaible\nAzrtQwer42!\nautre\n")
      wordlist.rewind

      findings = described_class.new(
        scope: AdminUser.where(id: user.id),
        wordlist_path: wordlist.path,
        thread_count: 1
      ).call

      expect(findings.first.category).to eq('générique')
    ensure
      wordlist.close!
    end

    it 'ignore les lignes vides et les espaces de fin' do
      user = FactoryBot.create(:admin_user, password: 'AzrtQwer42!')
      wordlist = Tempfile.new('wl')
      wordlist.write("\nAzrtQwer42!  \n\n")
      wordlist.rewind

      findings = described_class.new(
        scope: AdminUser.where(id: user.id),
        wordlist_path: wordlist.path,
        thread_count: 1
      ).call

      expect(findings.first.category).to eq('générique')
    ensure
      wordlist.close!
    end

    it 'échoue clairement quand le chemin de wordlist est introuvable (pas de faux négatif silencieux)' do
      FactoryBot.create(:admin_user, password: 'AzrtQwer42!')

      service = described_class.new(
        scope: AdminUser.all,
        wordlist_path: '/chemin/inexistant/wordlist.txt',
        thread_count: 1
      )

      expect { service.call }.to raise_error(ArgumentError, /introuvable/)
    end
  end

  describe 'robustesse' do
    it "fait remonter une exception survenue pendant l'audit d'un compte au lieu de l'avaler" do
      FactoryBot.create(:admin_user)
      service = described_class.new(scope: AdminUser.all, thread_count: 1)
      allow(service).to receive(:audit_user).and_raise(RuntimeError, 'boom')

      expect { service.call }.to raise_error(RuntimeError, 'boom')
    end
  end
end
