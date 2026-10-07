require 'rails_helper'
require 'rake'

RSpec.describe 'two_factor_rollout rake tasks' do
  before(:all) do
    Rake.application.rake_require('tasks/two_factor_rollout', [Rails.root.join('lib').to_s])
    Rake::Task.define_task(:environment)
  end

  describe 'admin_users:import_phone_numbers' do
    let(:task) { Rake::Task['admin_users:import_phone_numbers'] }

    before do
      task.reenable
      allow(ENV).to receive(:[]).and_call_original
    end

    # Comme en prod dans un conteneur, la valeur arrive sans encodage UTF-8.
    def tsv(*rows)
      content = [%w[Nom Email Téléphone], *rows].map { |row| row.join("\t") }.join("\n")
      allow(ENV).to receive(:[]).with('CSV_CONTENT').and_return(content.b)
    end

    it 'ne modifie rien en dry-run' do
      admin_user = FactoryBot.create(:admin_user, email: 'mcurie@1001mots.fr')
      tsv(['Curie', 'mcurie@1001mots.fr', '06 12 34 56 78'])

      expect { task.invoke }.to output(/DRY-RUN.*À mettre à jour \(1\)/m).to_stdout
      expect(admin_user.reload.phone_number).to be_nil
    end

    it 'retrouve le compte par email sans tenir compte de la casse, normalise et masque le numéro' do
      admin_user = FactoryBot.create(:admin_user, email: 'mcurie@1001mots.fr', phone_number: '0611111111')
      tsv(['Curie', 'MCurie@1001mots.fr', '06 12 34 56 78'])

      expect { task.invoke('apply') }.to output(/•• •• •• •• 78 \(remplace un numéro existant\)/).to_stdout
      expect(admin_user.reload.phone_number).to eq('+33612345678')
    end

    it 'signale les erreurs sans rien écrire ni effacer' do
      FactoryBot.create(:admin_user, email: 'ada@1001mots.fr', is_disabled: true)
      landline = FactoryBot.create(:admin_user, email: 'alan@1001mots.fr')
      unreadable = FactoryBot.create(:admin_user, email: 'grace@1001mots.fr', phone_number: '0611111111')
      tsv(
        %w[Lovelace ada@1001mots.fr 0612345678],
        %w[Turing alan@1001mots.fr 0140000000],
        %w[Hopper grace@1001mots.fr abc]
      )

      expect { task.invoke('apply') }.to output(/Erreurs \(3\)/).to_stdout
      expect(landline.reload.phone_number).to be_nil
      expect(unreadable.reload.phone_number).to eq('+33611111111')
    end
  end

  describe 'admin_users:enable_two_factor' do
    let(:task) { Rake::Task['admin_users:enable_two_factor'] }
    let!(:with_phone) { FactoryBot.create(:admin_user, phone_number: '0612345678', remember_created_at: Time.current) }
    let!(:without_phone) { FactoryBot.create(:admin_user, name: 'Sans Numéro') }
    let!(:disabled) { FactoryBot.create(:admin_user, phone_number: '0698765432', is_disabled: true) }

    before { task.reenable }

    it 'ne modifie rien en dry-run' do
      expect { task.invoke }.to output(/DRY-RUN/).to_stdout
      expect(with_phone.reload.two_factor_enabled).to be(false)
    end

    it 'active les comptes actifs avec numéro et oublie leurs sessions mémorisées' do
      expect { task.invoke('apply') }.to output(/faute de numéro\n- Sans Numéro/).to_stdout

      expect(with_phone.reload).to have_attributes(two_factor_enabled: true, remember_created_at: nil)
      expect(without_phone.reload.two_factor_enabled).to be(false)
      expect(disabled.reload.two_factor_enabled).to be(false)
    end
  end
end
