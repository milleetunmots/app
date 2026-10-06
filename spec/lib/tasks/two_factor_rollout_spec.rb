require 'rails_helper'
require 'rake'

RSpec.describe 'two_factor_rollout rake tasks' do
  before(:all) do
    Rake.application.rake_require('tasks/two_factor_rollout', [Rails.root.join('lib').to_s])
    Rake::Task.define_task(:environment)
  end

  describe 'admin_users:import_phone_numbers' do
    let(:task) { Rake::Task['admin_users:import_phone_numbers'] }
    let(:header) { %w[Nom Prénom Email Téléphone] }

    before do
      task.reenable
      allow(ENV).to receive(:[]).and_call_original
    end

    # Comme en prod dans un conteneur, la valeur arrive sans encodage UTF-8.
    def csv_content(content)
      allow(ENV).to receive(:[]).with('CSV_CONTENT').and_return(content.b)
    end

    # Format d'un copier-coller depuis Google Sheets : tabulations.
    def tsv(*rows)
      csv_content([header, *rows].map { |row| row.join("\t") }.join("\n"))
    end

    def run(mode = nil)
      expect { task.invoke(mode) }.to output.to_stdout
    end

    it 'ne modifie rien en dry-run' do
      admin_user = FactoryBot.create(:admin_user, name: 'Marie Curie', email: 'mcurie@1001mots.fr')
      tsv(%w[Curie Marie mcurie@1001mots.fr 0612345678])

      expect { task.invoke }.to output(/DRY-RUN.*Numéro ajouté \(1\)/m).to_stdout
      expect(admin_user.reload.phone_number).to be_nil
    end

    it 'retrouve le compte par email, quelle que soit la casse, même si le nom diffère' do
      admin_user = FactoryBot.create(:admin_user, name: 'M. Curie', email: 'mcurie@1001mots.fr')
      tsv(['Curie', 'Marie', 'MCurie@1001mots.fr', '06 12 34 56 78'])

      expect { task.invoke('apply') }.not_to output(/À vérifier/).to_stdout
      expect(admin_user.reload.phone_number).to eq('+33612345678')
    end

    it "se rabat sur le nom (accents, casse, ordre) quand l'email est inconnu et le signale" do
      prenom_nom = FactoryBot.create(:admin_user, name: 'Hélène Dupré', email: 'hdupre@1001mots.fr')
      nom_prenom = FactoryBot.create(:admin_user, name: 'MARTIN Paul', email: 'pmartin@1001mots.fr')
      tsv(%w[dupre helene helene.perso@gmail.com 0612345678], ['Martin', 'Paul', '', '0698765432'])

      expect { task.invoke('apply') }
        .to output(/À vérifier : trouvé par le nom, pas par l'email \(2\)/).to_stdout
      expect(prenom_nom.reload.phone_number).to eq('+33612345678')
      expect(nom_prenom.reload.phone_number).to eq('+33698765432')
    end

    it 'remplace un numéro existant et masque les numéros dans la sortie' do
      admin_user = FactoryBot.create(:admin_user, name: 'Marie Curie', email: 'mcurie@1001mots.fr', phone_number: '0611111111')
      tsv(%w[Curie Marie mcurie@1001mots.fr 0612345678])

      expect { task.invoke('apply') }
        .to output(/Numéro remplacé \(1\).*•• •• •• •• 11 → •• •• •• •• 78/m).to_stdout
      expect(admin_user.reload.phone_number).to eq('+33612345678')
    end

    it 'signale les lignes introuvables, ambiguës, invalides, désactivées et en doublon sans les écrire' do
      FactoryBot.create(:admin_user, name: 'Jean Dupont', email: 'jean1@1001mots.fr')
      FactoryBot.create(:admin_user, name: 'Dupont Jean', email: 'jean2@1001mots.fr')
      disabled = FactoryBot.create(:admin_user, name: 'Ada Lovelace', email: 'ada@1001mots.fr', is_disabled: true)
      landline = FactoryBot.create(:admin_user, name: 'Alan Turing', email: 'alan@1001mots.fr')
      double = FactoryBot.create(:admin_user, name: 'Grace Hopper', email: 'grace@1001mots.fr')
      tsv(
        %w[Inconnu Personne inconnu@gmail.com 0612345678],
        %w[Dupont Jean jean@gmail.com 0612345678],
        %w[Lovelace Ada ada@1001mots.fr 0612345678],
        %w[Turing Alan alan@1001mots.fr 0140000000],
        %w[Hopper Grace grace@1001mots.fr 0612345678],
        %w[Hopper Grace grace@1001mots.fr 0698765432]
      )

      expect { task.invoke('apply') }.to output(
        /Numéro ajouté \(1\).*Compte introuvable \(1\).*Plusieurs comptes possibles \(1\).*Numéro invalide \(1\).*Compte désactivé, ignoré \(1\).*Doublon dans le fichier \(1\)/m
      ).to_stdout

      expect(disabled.reload.phone_number).to be_nil
      expect(landline.reload.phone_number).to be_nil
      expect(double.reload.phone_number).to eq('+33612345678')
    end

    it 'accepte aussi un export Excel avec BOM et point-virgule' do
      admin_user = FactoryBot.create(:admin_user, name: 'Marie Curie', email: 'mcurie@1001mots.fr')
      csv_content("#{[0xFEFF].pack('U')}Nom;Prénom;Email;Téléphone\nCurie;Marie;mcurie@1001mots.fr;0612345678\n")

      run('apply')

      expect(admin_user.reload.phone_number).to eq('+33612345678')
    end

    it 'échoue si une colonne attendue manque' do
      csv_content("Nom\tPrénom\tTéléphone\nCurie\tMarie\t0612345678")

      expect { task.invoke('apply') }.to raise_error(SystemExit).and output(/colonnes manquantes : email/).to_stderr
    end

    it 'échoue sans rien écrire si CSV_CONTENT est vide' do
      csv_content('')

      expect { task.invoke('apply') }.to raise_error(SystemExit).and output(/CSV_CONTENT est vide/).to_stderr
    end
  end

  describe 'admin_users:enable_two_factor' do
    let(:task) { Rake::Task['admin_users:enable_two_factor'] }
    let!(:with_phone) { FactoryBot.create(:admin_user, name: 'Avec Numéro', phone_number: '0612345678', remember_created_at: Time.current) }
    let!(:without_phone) { FactoryBot.create(:admin_user, name: 'Sans Numéro', email: 'sans@1001mots.fr') }
    let!(:disabled) { FactoryBot.create(:admin_user, name: 'Désactivé', phone_number: '0698765432', is_disabled: true) }

    before { task.reenable }

    it 'ne modifie rien en dry-run' do
      expect { task.invoke }.to output(/DRY-RUN.*À activer \(1\)/m).to_stdout
      expect(with_phone.reload.two_factor_enabled).to be(false)
    end

    it 'active les comptes actifs avec numéro, oublie leurs sessions mémorisées et liste ceux sans numéro' do
      expect { task.invoke('apply') }
        .to output(/Activés \(1\).*Comptes actifs sans numéro, restent sans 2FA \(1\)\n- Sans Numéro <sans@1001mots.fr>/m).to_stdout

      expect(with_phone.reload).to have_attributes(two_factor_enabled: true, remember_created_at: nil)
      expect(without_phone.reload.two_factor_enabled).to be(false)
      expect(disabled.reload.two_factor_enabled).to be(false)
    end

    it 'est idempotent' do
      expect { task.invoke('apply') }.to output.to_stdout
      task.reenable

      expect { task.invoke('apply') }
        .to output(/Activés \(0\).*1 comptes avaient déjà la 2FA/m).to_stdout
    end
  end
end
