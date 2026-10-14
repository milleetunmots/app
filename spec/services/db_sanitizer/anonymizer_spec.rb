# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DbSanitizer::Anonymizer do
  subject(:anonymizer) { described_class.new }

  describe '#call' do
    let!(:parent) do
      FactoryBot.create(:parent,
        first_name: 'Cécile', last_name: 'Dupont', letterbox_name: 'Dupont C.',
        phone_number: '0612345678', phone_number_national: '0612345678',
        email: 'cecile.dupont@gmail.com', address: '12 rue des Lilas',
        address_supplement: 'Chez Mme Martin, bât. B',
        city_name: 'Lyon', job: 'Infirmière', aircall_id: 'AC123',
        security_token: 'realtoken', security_code: 'ab'
      )
    end

    let!(:parent_home_without_letterbox) do
      FactoryBot.create(:parent).tap { |p| p.update_columns(letterbox_name: nil, address_supplement: nil) }
    end

    let!(:parent_pmi) do
      FactoryBot.create(:parent, book_delivery_location: 'pmi', book_delivery_organisation_name: 'PMI des Lilas')
                .tap { |p| p.update_columns(letterbox_name: 'Nom Legacy') }
    end

    let!(:child) do
      FactoryBot.create(:child, parent1: parent,
        first_name: 'Emma', last_name: 'Dupont',
        security_code: 'cd', security_token: 'childtoken'
      )
    end

    let!(:child_support) do
      FactoryBot.create(:child_support, current_child: child,
        other_phone_number: '0698765432',
        notes: 'Famille difficile à joindre',
        call1_notes: 'Premier appel réussi'
      )
    end

    let!(:child_support_call_archive) do
      FactoryBot.create(:child_support_call_archive, child_support: child_support,
        call4_notes: 'Appel 4',
        call5_notes: 'Appel 5'
      )
    end

    before { anonymizer.call }

    context 'Parent' do
      subject { parent.reload }

      it 'replaces first_name' do
        expect(subject.first_name).not_to eq('Cécile')
      end

      it 'replaces last_name' do
        expect(subject.last_name).not_to eq('Dupont')
      end

      it 'sets phone_number to safe value' do
        expect(subject.phone_number).to eq('+33800000000')
      end

      it 'sets phone_number_national to safe value' do
        expect(subject.phone_number_national).to eq('+33800000000')
      end

      it 'replaces email with id-based value' do
        expect(subject.email).to eq("parent_#{parent.id}@example.com")
      end

      it 'replaces address' do
        expect(subject.address).not_to eq('12 rue des Lilas')
      end

      it 'replaces address with a realistic street address' do
        expect(subject.address).to match(/\A\d+ /)
      end

      it 'replaces city_name' do
        expect(subject.city_name).not_to eq('Lyon')
      end

      it 'replaces city_name with a realistic city name' do
        expect(subject.city_name).not_to eq('Ville fictive')
      end

      it 'replaces address_supplement with a fake one when present' do
        expect(subject.address_supplement).to be_present
        expect(subject.address_supplement).not_to eq('Chez Mme Martin, bât. B')
      end

      it 'sets letterbox_name to anonymized last_name' do
        expect(subject.letterbox_name).to eq(subject.last_name)
      end

      it 'stays valid' do
        expect(subject).to be_valid
      end

      it 'replaces job' do
        expect(subject.job).not_to eq('Infirmière')
      end

      it 'clears aircall_id' do
        expect(subject.aircall_id).to be_nil
      end

      it 'replaces security_token' do
        expect(subject.security_token).not_to eq('realtoken')
      end
    end

    context 'Parent delivered at home without letterbox_name (legacy data)' do
      subject { parent_home_without_letterbox.reload }

      it 'fills letterbox_name with the anonymized last_name' do
        expect(subject.letterbox_name).to eq(subject.last_name)
      end

      it 'leaves blank address_supplement blank' do
        expect(subject.address_supplement).to be_nil
      end

      it 'stays valid' do
        expect(subject).to be_valid
      end
    end

    context 'Parent delivered to an organisation (pmi)' do
      subject { parent_pmi.reload }

      it 'clears letterbox_name' do
        expect(subject.letterbox_name).to be_nil
      end

      it 'keeps book_delivery_organisation_name' do
        expect(subject.book_delivery_organisation_name).to eq('PMI des Lilas')
      end

      it 'stays valid' do
        expect(subject).to be_valid
      end
    end

    context 'Child' do
      subject { child.reload }

      it 'replaces first_name' do
        expect(subject.first_name).not_to eq('Emma')
      end

      it 'replaces last_name' do
        expect(subject.last_name).not_to eq('Dupont')
      end

      it 'replaces security_code' do
        expect(subject.security_code).not_to eq('cd')
      end

      it 'replaces security_token' do
        expect(subject.security_token).not_to eq('childtoken')
      end
    end

    context 'ChildSupport' do
      subject { child_support.reload }

      it 'sets other_phone_number to safe value' do
        expect(subject.other_phone_number).to eq('+33800000000')
      end

      it 'clears notes' do
        expect(subject.notes).to be_nil
      end

      it 'clears call notes' do
        expect(subject.call1_notes).to be_nil
      end

    end

    context 'ChildSupportCallArchive' do
      subject { child_support_call_archive.reload }

      it 'clears call4 notes' do
        expect(subject.call4_notes).to be_nil
      end

      it 'clears call5 notes' do
        expect(subject.call5_notes).to be_nil
      end
    end
  end

  describe '#call : informations sensibles' do
    subject(:anonymizer) { described_class.new }

    let(:texte_original) { 'Père placé en foyer, mesure d éloignement en cours' }
    let!(:fiche_avec_texte) do
      FactoryBot.create(:child_support, ok_for_solicitation: false).tap { |fiche| fiche.update!(sensitive_information: texte_original) }
    end
    let!(:fiche_menu_oui) do
      FactoryBot.create(:child_support, ok_for_solicitation: true).tap { |fiche| fiche.update!(sensitive_information: texte_original) }
    end
    let!(:fiche_texte_sans_menu) do
      FactoryBot.create(:child_support).tap { |fiche| fiche.update!(sensitive_information: texte_original) }
    end
    let!(:fiche_sans_texte) { FactoryBot.create(:child_support, ok_for_solicitation: true) }

    def valeur_brute(fiche)
      ChildSupport.find(fiche.id).read_attribute_before_type_cast(:sensitive_information)
    end

    context 'quand une fiche contient un texte sensible' do
      before { anonymizer.call }

      it 'le remplace par un texte différent de l\'original' do
        nouveau = fiche_avec_texte.reload.sensitive_information

        expect(nouveau).to be_present
        expect(nouveau).not_to eq(texte_original)
      end

      it 'ne garde rien de l\'original dans la colonne' do
        expect(valeur_brute(fiche_avec_texte)).not_to include('foyer')
        expect(valeur_brute(fiche_avec_texte)).not_to include('éloignement')
      end

      it 'stocke le nouveau texte chiffré' do
        nouveau = fiche_avec_texte.reload.sensitive_information

        expect(valeur_brute(fiche_avec_texte)).not_to include(nouveau)
      end
    end

    context 'quand une fiche n\'a pas de texte sensible' do
      before { anonymizer.call }

      it 'reste sans texte' do
        expect(fiche_sans_texte.reload.sensitive_information).to be_nil
        expect(valeur_brute(fiche_sans_texte)).to be_nil
      end
    end

    context 'pour le menu OK pour sollicitation' do
      before { anonymizer.call }

      it 'conserve Non' do
        expect(fiche_avec_texte.reload.ok_for_solicitation).to be(false)
      end

      it 'conserve Oui' do
        expect(fiche_menu_oui.reload.ok_for_solicitation).to be(true)
      end

      it 'conserve un menu vide, donc l\'état texte présent et menu vide' do
        fiche = fiche_texte_sans_menu.reload

        expect(fiche.ok_for_solicitation).to be_nil
        expect(fiche.solicitation_alert?).to be(true)
      end

      it 'conserve un menu renseigné sur une fiche sans texte' do
        expect(fiche_sans_texte.reload.ok_for_solicitation).to be(true)
      end
    end

    context 'quand le texte d\'origine ne peut pas être déchiffré avec les clés de cet environnement' do
      let!(:fiche_chiffree_ailleurs) do
        autre_clef = ActiveRecord::Encryption::DerivedSecretKeyProvider.new('clé de production')
        ActiveRecord::Encryption.with_encryption_context(key_provider: autre_clef) do
          FactoryBot.create(:child_support, sensitive_information: texte_original)
        end
      end

      it 'ne plante pas et rend le champ lisible avec les clés actuelles' do
        expect { anonymizer.call }.not_to raise_error

        nouveau = ChildSupport.find(fiche_chiffree_ailleurs.id).sensitive_information
        expect(nouveau).to be_present
        expect(nouveau).not_to eq(texte_original)
      end
    end

    context 'quand le texte contient du clair dans l\'historique' do
      it 'n\'a jamais écrit le texte dans les versions' do
        anonymizer.call

        historique = fiche_avec_texte.versions.map { |version| [version.object, version.object_changes] }.to_json
        expect(historique).not_to include('foyer')
      end
    end
  end
end
