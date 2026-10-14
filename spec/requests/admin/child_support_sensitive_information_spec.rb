require 'rails_helper'

RSpec.describe 'Admin infos sensibles de la fiche de suivi', type: :request do
  let(:texte) { 'Père placé en foyer' }
  let(:referente) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let!(:fiche) do
    FactoryBot.create(:child_support, supporter: referente).tap { |child_support| child_support.update!(sensitive_information: texte) }
  end
  let!(:fiche_sans_referente) do
    FactoryBot.create(:child_support, supporter: nil).tap { |child_support| child_support.update!(sensitive_information: texte) }
  end

  describe 'affichage du champ' do
    context 'pour la référente de la fiche' do
      before { sign_in referente }

      it 'affiche le texte et le libellé dans le formulaire' do
        get "/admin/child_supports/#{fiche.id}/edit", params: { r: 'true' }

        expect(response.body).to include('Infos sensibles')
        expect(response.body).to include(texte)
      end

      it 'affiche le texte dans la page de la fiche' do
        get "/admin/child_supports/#{fiche.id}"

        expect(response.body).to include('Infos sensibles')
        expect(response.body).to include(texte)
      end
    end

    %w[super_admin contributor reader animator].each do |role|
      context "pour un #{role} qui n'est pas la référente" do
        before { sign_in FactoryBot.create(:admin_user, user_role: role) }

        it 'ne montre ni le champ ni le texte dans le formulaire' do
          get "/admin/child_supports/#{fiche.id}/edit", params: { r: 'true' }

          expect(response.body).not_to include('Infos sensibles')
          expect(response.body).not_to include(texte)
        end

        it 'ne montre ni le champ ni le texte dans la page de la fiche' do
          get "/admin/child_supports/#{fiche.id}"

          expect(response.body).not_to include('Infos sensibles')
          expect(response.body).not_to include(texte)
        end
      end
    end

    context 'quand la fiche n\'a pas de référente' do
      %w[super_admin contributor reader animator].each do |role|
        it "ne montre le champ à aucun #{role}" do
          sign_in FactoryBot.create(:admin_user, user_role: role)
          get "/admin/child_supports/#{fiche_sans_referente.id}/edit", params: { r: 'true' }

          expect(response.body).not_to include('Infos sensibles')
          expect(response.body).not_to include(texte)
        end
      end
    end

    context 'quand le supporter est retiré de la fiche' do
      it 'rend le champ inaccessible à tous et garde le contenu chiffré' do
        admin = FactoryBot.create(:admin_user, user_role: 'super_admin')
        sign_in admin
        patch "/admin/child_supports/#{fiche.id}", params: { child_support: { supporter_id: '' } }
        fiche.reload

        expect(fiche.supporter_id).to be_nil
        expect(fiche.sensitive_information).to eq(texte)

        get "/admin/child_supports/#{fiche.id}/edit", params: { r: 'true' }
        expect(response.body).not_to include(texte)

        sign_in referente
        get "/admin/child_supports/#{fiche.id}/edit", params: { r: 'true' }
        expect(response.body).not_to include(texte)
      end
    end

    context 'quand la valeur ne peut pas être déchiffrée' do
      let!(:fiche_illisible) do
        autre_clef = ActiveRecord::Encryption::DerivedSecretKeyProvider.new('une autre clé')
        ActiveRecord::Encryption.with_encryption_context(key_provider: autre_clef) do
          FactoryBot.create(:child_support, supporter: referente, sensitive_information: texte)
        end
      end

      before { sign_in referente }

      it "n'empêche pas d'ouvrir la fiche" do
        allow(Rollbar).to receive(:error)

        get "/admin/child_supports/#{fiche_illisible.id}/edit", params: { r: 'true' }

        expect(response).to have_http_status(:ok)
      end

      it "journalise l'erreur de déchiffrement" do
        expect(Rollbar).to receive(:error).with(anything, hash_including(child_support_id: fiche_illisible.id)).at_least(:once)

        get "/admin/child_supports/#{fiche_illisible.id}"
      end
    end
  end

  describe 'enregistrement du champ' do
    context 'par la référente' do
      it 'enregistre le nouveau texte' do
        sign_in referente

        patch "/admin/child_supports/#{fiche.id}", params: { child_support: { sensitive_information: 'Mère hospitalisée' } }

        expect(fiche.reload.sensitive_information).to eq('Mère hospitalisée')
      end
    end

    %w[super_admin contributor reader animator].each do |role|
      context "par un #{role} qui n'est pas la référente, avec une requête forgée" do
        before do
          sign_in FactoryBot.create(:admin_user, user_role: role)
          patch "/admin/child_supports/#{fiche.id}", params: { child_support: { sensitive_information: 'Texte pirate', notes: 'Note ordinaire' } }
        end

        it 'ne modifie pas le champ' do
          expect(fiche.reload.sensitive_information).to eq(texte)
        end

        it "n'empêche pas la modification des autres champs" do
          expect(fiche.reload.notes).to eq('Note ordinaire')
        end
      end

      context "par un #{role} sur une fiche sans référente, avec une requête forgée" do
        it 'ne modifie pas le champ' do
          sign_in FactoryBot.create(:admin_user, user_role: role)

          patch "/admin/child_supports/#{fiche_sans_referente.id}", params: { child_support: { sensitive_information: 'Texte pirate' } }

          expect(fiche_sans_referente.reload.sensitive_information).to eq(texte)
        end
      end
    end
  end

  describe 'fuites par les exports et les filtres' do
    let(:exporteur) { FactoryBot.create(:admin_user, user_role: 'super_admin', can_export_data: true) }

    before { sign_in exporteur }

    it "n'inclut pas le champ dans l'export CSV" do
      get '/admin/child_supports.csv', params: { scope: 'all' }

      expect(response.body).to include(fiche.id.to_s)
      expect(response.body).not_to include(texte)
      expect(response.body).not_to include('sensitive_information')
    end

    it "n'inclut pas le champ dans le JSON de la liste" do
      get '/admin/child_supports.json', params: { scope: 'all' }

      expect(response.body).to include(fiche.id.to_s)
      expect(response.body).not_to include(texte)
      expect(response.body).not_to include('sensitive_information')
    end

    it "n'inclut pas le champ dans le JSON d'une fiche" do
      get "/admin/child_supports/#{fiche.id}.json"

      expect(response.body).not_to include(texte)
      expect(response.body).not_to include('sensitive_information')
    end

    it "n'inclut pas le champ dans le XML d'une fiche" do
      get "/admin/child_supports/#{fiche.id}.xml"

      expect(response.body).not_to include(texte)
      expect(response.body).not_to include('sensitive-information')
    end

    it "ne propose aucun filtre sur le champ dans la liste" do
      get '/admin/child_supports', params: { scope: 'all' }

      expect(response.body).not_to include('sensitive_information')
    end
  end
end
