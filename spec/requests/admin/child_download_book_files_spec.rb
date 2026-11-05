require 'rails_helper'

RSpec.describe 'Téléchargement des listes par module sans cohorte', type: :request do
  let!(:group) { create_group }
  let!(:ended_group) { create_group(ended_at: Time.zone.today - 1.day) }
  let!(:book) { FactoryBot.create(:book) }
  let!(:support_module) { FactoryBot.create(:support_module, book: book) }
  let!(:children_support_module) { create_module(group: group) }
  let!(:ended_group_children_support_module) { create_module(group: ended_group, group_status: 'stopped') }
  let!(:admin_user) { FactoryBot.create(:admin_user, user_role: 'contributor', can_export_data: true) }
  let(:download_path) { '/admin/children/download_book_files_v2' }

  before do
    sign_in admin_user
    allow(Rollbar).to receive(:error)
  end

  def create_group(**columns)
    FactoryBot.create(:group).tap { |group| group.update_columns(support_module_programmed: 2, **columns) }
  end

  # le statut est posé après la création : la validation exige une cohorte en cours pour certains statuts
  def create_module(group:, group_status: 'active')
    child = FactoryBot.create(:child, group: group, group_status: 'active')
    child.update_column(:group_status, group_status)
    FactoryBot.create(:children_support_module, child: child, parent: child.parent1, support_module: support_module)
  end

  def download_with(freeze_books)
    post download_path, params: { freeze_books: freeze_books }.compact
  end

  it 'affiche la question avant le téléchargement' do
    get download_path

    expect(response.body).to include('Enregistrer les choix de livres ?')
    expect(response.body).to include('Télécharger')
    expect(children_support_module.reload[:book_id]).to be_nil
  end

  context 'avec Oui' do
    it 'enregistre les livres de la cohorte en cours et télécharge le fichier' do
      download_with('true')

      expect(response.media_type).to eq('application/zip')
      expect(children_support_module.reload[:book_id]).to eq(book.id)
    end

    it "n'enregistre pas les livres de la cohorte terminée" do
      download_with('true')

      expect(ended_group_children_support_module.reload[:book_id]).to be_nil
    end

    it 'enregistre le LogisticExport de la seule cohorte en cours' do
      expect { download_with('true') }.to change(LogisticExport, :count).by(1)

      expect(LogisticExport.last.group_modules).to eq([{ 'group_id' => group.id, 'module_number' => 2 }])
    end
  end

  context 'avec Non' do
    it "télécharge le fichier sans LogisticExport ni livre enregistré, comme aujourd'hui" do
      expect { download_with('false') }.not_to change(LogisticExport, :count)

      expect(response.media_type).to eq('application/zip')
      expect(children_support_module.reload[:book_id]).to be_nil
    end
  end

  context 'sans réponse' do
    it 'refuse le téléchargement sans rien enregistrer' do
      expect { download_with(nil) }.not_to change(LogisticExport, :count)

      follow_redirect!
      expect(response.body).to include('Indiquez si les choix de livres doivent être enregistrés')
      expect(children_support_module.reload[:book_id]).to be_nil
    end
  end
end
