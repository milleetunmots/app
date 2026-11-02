require 'rails_helper'

RSpec.describe 'Export logistique groupé des cohortes', type: :request do
  let!(:group) { create_group(support_module_programmed: 2) }
  let!(:book) { FactoryBot.create(:book) }
  let!(:support_module) { FactoryBot.create(:support_module, book: book) }
  let!(:children_support_module) { create_module(group: group) }
  let!(:admin_user) { FactoryBot.create(:admin_user, user_role: 'contributor', can_export_data: true) }

  before do
    sign_in admin_user
    allow(Rollbar).to receive(:error)
  end

  def create_group(support_module_programmed:)
    FactoryBot.create(:group).tap { |group| group.update_column(:support_module_programmed, support_module_programmed) }
  end

  def create_module(group:, support_module: self.support_module)
    child = FactoryBot.create(:child, group: group, group_status: 'active')
    FactoryBot.create(:children_support_module, child: child, parent: child.parent1, support_module: support_module)
  end

  def export_with(freeze_books, groups: [group])
    inputs = freeze_books.nil? ? {} : { 'Enregistrer les choix de livres ?' => freeze_books }
    post '/admin/groups/batch_action', params: {
      batch_action: 'support_modules_chosen_excel_export',
      collection_selection: groups.map(&:id),
      batch_action_inputs: inputs.to_json
    }
  end

  it 'propose Oui et Non après une option vide' do
    get '/admin/groups'

    expect(response.body).to include(CGI.escapeHTML({ 'Enregistrer les choix de livres ?' => [['', ''], %w[Oui true], %w[Non false]] }.to_json))
  end

  context 'avec Oui' do
    it 'enregistre les livres et télécharge le fichier' do
      expect { export_with('true') }.to change(LogisticExport, :count).by(1)

      expect(response.media_type).to eq('application/zip')
      expect(children_support_module.reload[:book_id]).to eq(book.id)
    end

    context "quand l'une des cohortes n'en est qu'au Module 1" do
      let!(:module_one_group) { create_group(support_module_programmed: 1) }
      let!(:module_one_children_support_module) { create_module(group: module_one_group) }

      it "n'enregistre que les livres de la cohorte au Module 2" do
        export_with('true', groups: [group, module_one_group])

        expect(response.media_type).to eq('application/zip')
        expect(children_support_module.reload[:book_id]).to eq(book.id)
        expect(module_one_children_support_module.reload[:book_id]).to be_nil
      end
    end
  end

  context 'avec Non' do
    it 'télécharge le fichier sans enregistrer les livres' do
      export_with('false')

      expect(response.media_type).to eq('application/zip')
      expect(children_support_module.reload[:book_id]).to be_nil
    end
  end

  context 'sans réponse' do
    it "refuse l'export sans rien enregistrer" do
      expect { export_with(nil) }.not_to change(LogisticExport, :count)

      expect(flash[:alert]).to eq('Indiquez si les choix de livres doivent être enregistrés')
      expect(children_support_module.reload[:book_id]).to be_nil
    end
  end

  context "quand un enfant actif n'a pas choisi de module" do
    before { create_module(group: group, support_module: nil) }

    %w[true false].each do |freeze_books|
      it "refuse l'export avec la réponse #{freeze_books}" do
        expect { export_with(freeze_books) }.not_to change(LogisticExport, :count)

        expect(flash[:alert]).to eq("Dans la cohorte #{group.name}, il y a des enfants sans choix de module.")
        expect(children_support_module.reload[:book_id]).to be_nil
      end
    end
  end

  context 'quand les modules de la cohorte sont déjà programmés' do
    before { children_support_module.update_column(:is_programmed, true) }

    it "refuse l'export" do
      export_with('true')

      expect(flash[:alert]).to eq("Les modules de la cohorte #{group.name} ont déjà été programmés")
    end
  end
end
