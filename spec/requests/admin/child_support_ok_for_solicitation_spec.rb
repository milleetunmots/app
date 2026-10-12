require 'rails_helper'

RSpec.describe "Admin menu OK pour sollicitation de la fiche de suivi", type: :request do
  let(:texte) { 'Père placé en foyer' }
  let(:referente) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let!(:fiche) { FactoryBot.create(:child_support, supporter: referente) }
  let!(:fiche_sans_referente) { FactoryBot.create(:child_support, supporter: nil) }

  def menu(path)
    get path, params: { r: 'true' }
    Nokogiri::HTML(response.body).at_css('select#child_support_ok_for_solicitation')
  end

  describe "affichage du menu" do
    context "pour la référente de la fiche" do
      before { sign_in referente }

      it "affiche un menu modifiable et vide par défaut" do
        select = menu("/admin/child_supports/#{fiche.id}/edit")

        expect(select).to be_present
        expect(select['disabled']).to be_nil
        expect(select.css('option[selected]')).to be_empty
        expect(select.css('option').map(&:text)).to include('Oui', 'Non')
      end

      it "place le menu sous le champ Infos sensibles" do
        menu("/admin/child_supports/#{fiche.id}/edit")

        expect(response.body.index('id="child_support_ok_for_solicitation"')).to be > response.body.index('id="child_support_sensitive_information"')
      end
    end

    %w[super_admin contributor reader animator].each do |role|
      context "pour un #{role} qui n'est pas la référente" do
        before { sign_in FactoryBot.create(:admin_user, user_role: role) }

        it "n'affiche pas le menu dans le formulaire" do
          expect(menu("/admin/child_supports/#{fiche.id}/edit")).to be_nil
        end
      end
    end

    context "quand la fiche n'a pas de référente" do
      %w[super_admin contributor reader animator].each do |role|
        it "n'affiche le menu à aucun #{role}" do
          sign_in FactoryBot.create(:admin_user, user_role: role)

          expect(menu("/admin/child_supports/#{fiche_sans_referente.id}/edit")).to be_nil
        end
      end
    end
  end

  describe "alerte quand un texte sensible est présent" do
    context "quand la fiche a un texte sensible" do
      before { fiche.update!(sensitive_information: texte) }

      %w[super_admin contributor reader animator].each do |role|
        it "ne l'affiche pas à un #{role} qui n'est pas le supporter, et ne montre pas le texte" do
          sign_in FactoryBot.create(:admin_user, user_role: role)

          get "/admin/child_supports/#{fiche.id}/edit", params: { r: 'true' }

          expect(response.body).not_to include('sensitive-information-alert')
          expect(response.body).not_to include(texte)
        end
      end

      it "l'affiche à la référente" do
        sign_in referente

        get "/admin/child_supports/#{fiche.id}/edit", params: { r: 'true' }

        expect(response.body).to include('sensitive-information-alert')
      end
    end

    context "quand la fiche n'a pas de texte sensible" do
      it "ne l'affiche pas" do
        sign_in referente

        get "/admin/child_supports/#{fiche.id}/edit", params: { r: 'true' }

        expect(response.body).not_to include('sensitive-information-alert')
      end
    end

    context "quand le menu est vide et le texte présent" do
      it "garde l'alerte et accepte l'enregistrement" do
        sign_in referente

        patch "/admin/child_supports/#{fiche.id}",
              params: { child_support: { sensitive_information: texte, ok_for_solicitation: '' } }
        get "/admin/child_supports/#{fiche.id}/edit", params: { r: 'true' }

        expect(fiche.reload.ok_for_solicitation).to be_nil
        expect(response.body).to include('sensitive-information-alert')
      end
    end
  end

  describe "enregistrement du menu" do
    context "par la référente" do
      before { sign_in referente }

      it "enregistre Non" do
        patch "/admin/child_supports/#{fiche.id}", params: { child_support: { ok_for_solicitation: 'false' } }

        expect(fiche.reload.ok_for_solicitation).to be(false)
      end

      it "enregistre Oui" do
        patch "/admin/child_supports/#{fiche.id}", params: { child_support: { ok_for_solicitation: 'true' } }

        expect(fiche.reload.ok_for_solicitation).to be(true)
      end

      it "garde Non quand le formulaire est envoyé avec un texte sensible toujours vide" do
        fiche.update!(ok_for_solicitation: false)

        patch "/admin/child_supports/#{fiche.id}",
              params: { child_support: { sensitive_information: '', ok_for_solicitation: 'false' } }

        expect(fiche.reload.ok_for_solicitation).to be(false)
      end

      it "remet le menu à vide et retire l'alerte quand le texte est vidé" do
        fiche.update!(sensitive_information: texte, ok_for_solicitation: false)

        patch "/admin/child_supports/#{fiche.id}", params: { child_support: { sensitive_information: '' } }
        get "/admin/child_supports/#{fiche.id}/edit", params: { r: 'true' }

        expect(fiche.reload.ok_for_solicitation).to be_nil
        expect(response.body).not_to include('sensitive-information-alert')
      end
    end

    %w[super_admin contributor reader animator].each do |role|
      context "par un #{role} qui n'est pas la référente, avec une requête forgée" do
        before do
          fiche.update!(ok_for_solicitation: false)
          sign_in FactoryBot.create(:admin_user, user_role: role)
          patch "/admin/child_supports/#{fiche.id}",
                params: { child_support: { ok_for_solicitation: 'true', notes: 'Note ordinaire' } }
        end

        it "ne modifie pas le menu" do
          expect(fiche.reload.ok_for_solicitation).to be(false)
        end

        it "n'empêche pas la modification des autres champs" do
          expect(fiche.reload.notes).to eq('Note ordinaire')
        end
      end
    end

    %w[super_admin contributor reader animator].each do |role|
      context "par un #{role} sur une fiche sans référente, avec une requête forgée" do
        it "ne modifie pas le menu" do
          sign_in FactoryBot.create(:admin_user, user_role: role)

          patch "/admin/child_supports/#{fiche_sans_referente.id}", params: { child_support: { ok_for_solicitation: 'false' } }

          expect(fiche_sans_referente.reload.ok_for_solicitation).to be_nil
        end
      end
    end
  end
end
