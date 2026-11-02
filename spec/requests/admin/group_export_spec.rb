require 'rails_helper'

RSpec.describe 'Export logistique depuis la fiche cohorte', type: :request do
  let!(:group) { FactoryBot.create(:group).tap { |group| group.update_column(:support_module_programmed, 2) } }
  let!(:book) { FactoryBot.create(:book) }
  let!(:support_module) { FactoryBot.create(:support_module, book: book) }
  let!(:child) { FactoryBot.create(:child, group: group, group_status: 'active') }
  let!(:children_support_module) do
    FactoryBot.create(:children_support_module, child: child, parent: child.parent1, support_module: support_module)
  end
  let!(:admin_user) { FactoryBot.create(:admin_user, user_role: 'contributor') }
  let(:export_path) { "/admin/groups/#{group.id}/export" }

  before do
    sign_in admin_user
    allow(Rollbar).to receive(:error)
  end

  def export_with(freeze_books)
    post export_path, params: { freeze_books: freeze_books }.compact
  end

  it 'affiche la question avant le téléchargement' do
    get export_path

    expect(response.body).to include('Enregistrer les choix de livres ?')
    expect(response.body).to include('Télécharger')
    expect(children_support_module.reload[:book_id]).to be_nil
  end

  context 'avec Oui' do
    it 'enregistre les livres et télécharge le fichier' do
      expect { export_with('true') }.to change(LogisticExport, :count).by(1)

      expect(response.media_type).to eq('application/zip')
      expect(children_support_module.reload[:book_id]).to eq(book.id)
    end

    context 'quand les modules de la cohorte sont déjà programmés' do
      before { children_support_module.update_column(:is_programmed, true) }

      it "refuse l'export" do
        expect { export_with('true') }.not_to change(LogisticExport, :count)

        follow_redirect!
        expect(response.body).to include("Les modules de la cohorte #{group.name} ont déjà été programmés")
      end
    end

    context "quand un enfant actif n'a pas choisi de module" do
      before do
        other_child = FactoryBot.create(:child, group: group, group_status: 'active')
        FactoryBot.create(:children_support_module, child: other_child, parent: other_child.parent1, support_module: nil)
      end

      it "refuse l'export sans rien enregistrer" do
        expect { export_with('true') }.not_to change(LogisticExport, :count)

        follow_redirect!
        expect(response.body).to include("Dans la cohorte #{group.name}, il y a des enfants sans choix de module.")
        expect(children_support_module.reload[:book_id]).to be_nil
      end
    end

    context "quand l'enregistrement du LogisticExport échoue" do
      before do
        allow_any_instance_of(LogisticExport).to receive(:save!).and_raise(ActiveRecord::ActiveRecordError, 'stockage indisponible')
      end

      it 'ne télécharge rien et affiche l’erreur' do
        export_with('true')

        expect(response.media_type).not_to eq('application/zip')
        follow_redirect!
        expect(response.body).to include('Export logistique en échec : stockage indisponible')
        expect(children_support_module.reload[:book_id]).to be_nil
      end
    end
  end

  context 'avec Non' do
    it 'télécharge le fichier sans enregistrer les livres' do
      export_with('false')

      expect(response.media_type).to eq('application/zip')
      expect(children_support_module.reload[:book_id]).to be_nil
    end

    context "quand un enfant actif n'a pas choisi de module" do
      before do
        other_child = FactoryBot.create(:child, group: group, group_status: 'active')
        FactoryBot.create(:children_support_module, child: other_child, parent: other_child.parent1, support_module: nil)
      end

      it "télécharge le fichier comme aujourd'hui" do
        export_with('false')

        expect(response.media_type).to eq('application/zip')
      end
    end
  end

  context 'sans réponse' do
    it "refuse l'export sans rien enregistrer" do
      expect { export_with(nil) }.not_to change(LogisticExport, :count)

      follow_redirect!
      expect(response.body).to include('Indiquez si les choix de livres doivent être enregistrés')
      expect(children_support_module.reload[:book_id]).to be_nil
    end
  end
end
