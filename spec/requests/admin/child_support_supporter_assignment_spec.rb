require 'rails_helper'

RSpec.describe "Admin changement du supporter d'une fiche de suivi", type: :request do
  let(:liste) { 'camille@1001mots.org' }
  let(:referente) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let(:binta) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let!(:fiche) { FactoryBot.create(:child_support, supporter: referente) }
  let(:libelle_action_de_masse) { I18n.t('activerecord.attributes.child_support.supporter') }

  before { stub_const('ENV', ENV.to_h.merge('SUPPORTER_ASSIGNMENT_EMAILS' => liste)) }

  def champ_supporter(path)
    get path, params: { r: 'true' }
    Nokogiri::HTML(response.body).at_css('select#child_support_supporter_id')
  end

  def utilisateur(nom)
    case nom
    when :super_admin then FactoryBot.create(:admin_user, user_role: 'super_admin')
    when :contributor_liste then FactoryBot.create(:admin_user, user_role: 'contributor', email: 'camille@1001mots.org')
    when :contributor_non_liste then FactoryBot.create(:admin_user, user_role: 'contributor', email: 'dominique@1001mots.org')
    when :reader then FactoryBot.create(:admin_user, user_role: 'reader')
    when :animator then FactoryBot.create(:admin_user, user_role: 'animator')
    when :supporter then referente
    end
  end

  def action_de_masse(supporter_choisi, fiches)
    post '/admin/child_supports/batch_action', params: {
      batch_action: 'assign_supporter',
      batch_action_inputs: { libelle_action_de_masse => supporter_choisi.id }.to_json,
      collection_selection: fiches.map(&:id),
      scope: 'all' # sans lui, la collection se limite aux fiches du connecté et la garde ne serait pas éprouvée
    }, headers: { 'HTTP_REFERER' => '/admin/child_supports' }
  end

  autorises = %i[super_admin contributor_liste]
  refuses = %i[contributor_non_liste reader animator supporter]

  describe "formulaire de la fiche" do
    autorises.each do |nom|
      it "laisse #{nom} modifier le champ Accompagnante" do
        sign_in utilisateur(nom)

        select = champ_supporter("/admin/child_supports/#{fiche.id}/edit")

        expect(select).to be_present
        expect(select['disabled']).to be_nil
      end
    end

    refuses.each do |nom|
      it "affiche le champ Accompagnante désactivé pour #{nom}" do
        sign_in utilisateur(nom)

        select = champ_supporter("/admin/child_supports/#{fiche.id}/edit")

        expect(select).to be_present
        expect(select['disabled']).to be_present
      end
    end
  end

  describe "enregistrement d'un autre supporter" do
    autorises.each do |nom|
      it "est accepté pour #{nom}" do
        sign_in utilisateur(nom)

        patch "/admin/child_supports/#{fiche.id}", params: { child_support: { supporter_id: binta.id } }

        expect(fiche.reload.supporter_id).to eq(binta.id)
      end
    end

    refuses.each do |nom|
      context "avec une requête forgée de #{nom}" do
        before do
          sign_in utilisateur(nom)
          patch "/admin/child_supports/#{fiche.id}", params: { child_support: { supporter_id: binta.id, notes: 'Note ordinaire' } }
        end

        it "ne change pas le supporter" do
          expect(fiche.reload.supporter_id).to eq(referente.id)
        end

        it "n'empêche pas la modification des autres champs" do
          expect(fiche.reload.notes).to eq('Note ordinaire')
        end
      end
    end

    context "quand la liste d'e-mails est vide" do
      let(:liste) { '' }

      it "refuse à un contributeur qui était listé" do
        sign_in utilisateur(:contributor_liste)

        patch "/admin/child_supports/#{fiche.id}", params: { child_support: { supporter_id: binta.id } }

        expect(fiche.reload.supporter_id).to eq(referente.id)
      end

      it "reste accepté pour un super_admin" do
        sign_in utilisateur(:super_admin)

        patch "/admin/child_supports/#{fiche.id}", params: { child_support: { supporter_id: binta.id } }

        expect(fiche.reload.supporter_id).to eq(binta.id)
      end
    end
  end

  describe "action de masse « Accompagnante »" do
    autorises.each do |nom|
      it "est proposée à #{nom}" do
        sign_in utilisateur(nom)

        get '/admin/child_supports', params: { scope: 'all' }

        expect(response.body).to include('data-action="assign_supporter"').or include("batch_action_item_assign_supporter")
      end

      it "change le supporter quand #{nom} l'utilise" do
        sign_in utilisateur(nom)

        action_de_masse(binta, [fiche])

        expect(fiche.reload.supporter_id).to eq(binta.id)
      end
    end

    refuses.each do |nom|
      it "n'est pas proposée à #{nom}" do
        sign_in utilisateur(nom)

        get '/admin/child_supports', params: { scope: 'all' }

        expect(response.body).not_to include('data-action="assign_supporter"')
        expect(response.body).not_to include("batch_action_item_assign_supporter")
      end

      it "ne change pas le supporter quand #{nom} forge la requête" do
        sign_in utilisateur(nom)

        action_de_masse(binta, [fiche])

        expect(fiche.reload.supporter_id).to eq(referente.id)
      end
    end
  end
end
