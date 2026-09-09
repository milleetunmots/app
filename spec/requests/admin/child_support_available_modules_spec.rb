require 'rails_helper'

RSpec.describe 'Admin child support available support modules', type: :request do
  let!(:group) { FactoryBot.create(:group, started_at: 8.weeks.ago.prev_occurring(:monday), ended_at: 8.weeks.from_now) }
  let!(:child) { FactoryBot.create(:child, group: group, group_status: 'active') }
  let!(:linked_module) do
    FactoryBot.create(:support_module,
                      name: 'Chanter avec mon enfant ♪♪',
                      age_ranges: [SupportModule::TWELVE_TO_SEVENTEEN])
  end
  let!(:unlinked_module) do
    FactoryBot.create(:support_module,
                      name: 'Parler avec mon bébé 👶',
                      age_ranges: [SupportModule::TWELVE_TO_SEVENTEEN])
  end

  let!(:child_support) do
    child.child_support.tap do |cs|
      cs.update!(parent1_available_support_module_list: [linked_module.id.to_s, unlinked_module.id.to_s])
    end
  end

  let(:edit_path) { "/admin/child_supports/#{child_support.id}/edit" }

  # Le lien d'un bloc vient du contenu apparié sur Airtable : on stubbe la
  # classe Airtables::*, jamais le HTTP, comme les autres specs du projet
  let(:content_url) { 'https://airtable.com/appTEST/shrrFRdYIrDKqvy1u/tblTEST/viwvzXW4OIZ0flR7h/recAAA' }

  before do
    allow(Airtables::SupportModuleContent).to receive(:record_url_for) do |support_module|
      content_url if support_module&.id == linked_module.id
    end
  end

  # la fiche redirige vers l'onglet de l'appel en cours
  def visit_edit_page
    get edit_path
    follow_redirect! while response.redirect?
  end

  def sign_in_as(user_role)
    admin_user = FactoryBot.create(:admin_user, user_role: user_role)
    child_support.update!(supporter: admin_user) if user_role.in?(%w[caller animator])
    sign_in admin_user
    admin_user
  end

  shared_examples 'la vue lecture en blocs' do
    it "affiche un bloc par module disponible, dont le nom est débarrassé de l'emoji" do
      visit_edit_page

      expect(response.body).to include('<span class="support-module-block__name">Chanter avec mon enfant</span>')
      expect(response.body).to include('<span class="support-module-block__name">Parler avec mon bébé</span>')
    end

    it "affiche la tranche d'âge à côté du nom du module" do
      visit_edit_page

      expect(response.body).to include('support-module-block__age')
      expect(response.body).to include('12-17')
    end

    it 'rend le module relié cliquable vers son enregistrement Airtable, dans un nouvel onglet' do
      visit_edit_page

      expect(response.body).to include(content_url)
      expect(response.body).to include('support-module-block--recommended')
    end

    it "n'ouvre pas de lien pour un module non relié à Airtable" do
      visit_edit_page

      expect(response.body).to include('support-module-block--unlinked')
    end
  end

  %w[super_admin contributor].each do |user_role|
    context "en tant que #{user_role}" do
      before { sign_in_as(user_role) }

      include_examples 'la vue lecture en blocs'

      it 'propose de basculer en édition' do
        visit_edit_page

        expect(response.body).to include('support-module-edit-toggle')
      end

      it "rend le select2 d'édition actif mais masqué au chargement" do
        visit_edit_page

        expect(response.body).to match(/<li class="initially-hidden[^"]*" id="child_support_parent1_available_support_module_list_input"/)
        expect(response.body).not_to match(/id="child_support_parent1_available_support_module_list"[^>]*disabled/)
      end
    end
  end

  %w[reader caller animator].each do |user_role|
    context "en tant que #{user_role}" do
      before { sign_in_as(user_role) }

      include_examples 'la vue lecture en blocs'

      it 'ne propose pas de basculer en édition' do
        visit_edit_page

        expect(response.body).not_to include('support-module-edit-toggle')
      end

      it 'laisse le select2 désactivé' do
        visit_edit_page

        expect(response.body).to match(/id="child_support_parent1_available_support_module_list"[^>]*disabled/)
      end
    end
  end

  # « Tous les modules en cours de programmation doivent être cliquables »
  describe 'modules déjà choisis / programmés' do
    let!(:book) { FactoryBot.create(:book) }
    let!(:children_support_module) do
      linked_module.update!(book: book)
      FactoryBot.create(:children_support_module,
                        child: child,
                        parent: child.parent1,
                        support_module: linked_module,
                        book: book)
    end

    before { sign_in_as('caller') }

    it "rend le module cliquable depuis l'onglet logistique" do
      visit_edit_page

      expect(response.body).to include('support-module-airtable-link')
      expect(response.body).to include(content_url)
    end

    it 'rend le module cliquable depuis la fiche du module choisi' do
      get "/admin/children_support_modules/#{children_support_module.id}/edit"

      expect(response.body).to include(content_url)
      expect(response.body).to include('Voir le contenu du module sur Airtable')
    end
  end
end
