require 'rails_helper'

RSpec.describe 'Admin book SAV import', type: :request do
  let!(:group) { FactoryBot.create(:group) }
  let!(:child) { FactoryBot.create(:child, group: group, group_status: 'active') }
  let!(:book) { FactoryBot.create(:book) }
  let!(:support_module) do
    FactoryBot.create(:children_support_module, child: child, parent: child.parent1, book: book, book_condition: 'not_received')
  end
  let!(:admin_user) { FactoryBot.create(:admin_user, user_role: 'contributor') }

  before { sign_in admin_user }

  def csv_upload_with(content)
    file = Tempfile.new(['sav_import', '.csv'])
    file.write("Date d'envoi fichier SAV YLS,Children Support Modules → ID,Book condition\n#{content}")
    file.rewind
    Rack::Test::UploadedFile.new(file.path, 'text/csv')
  end

  it "affiche le bouton 'Gestion du SAV' sur la page catalogue des livres" do
    get '/admin/books'
    expect(response.body).to include('Gestion du SAV')
  end

  it 'affiche le formulaire de dépôt du fichier CSV' do
    get '/admin/books/new_sav_import'

    expect(response.body).to include('Fichier csv')
    expect(response.body).to include('Valider')
  end

  describe 'POST /admin/books/perform_sav_import' do
    it 'met à jour la fiche matchée et affiche le nombre de lignes traitées' do
      post '/admin/books/perform_sav_import', params: { csv_file: csv_upload_with("05/08/2026,#{support_module.id},not_received\n") }

      expect(response.body).to include('1 ligne(s) traitée(s) avec succès')
      expect(support_module.reload.book_resent_on).to eq(Date.new(2026, 8, 5))
    end

    it "signale une ligne en erreur sans bloquer l'import" do
      post '/admin/books/perform_sav_import', params: { csv_file: csv_upload_with("05/08/2026,0,not_received\n") }

      expect(response.body).to include('1 ligne(s) en erreur')
    end

    it 'renvoie au formulaire avec une alerte quand aucun fichier n\'est fourni' do
      expect(Book::SavImportService).not_to receive(:new)

      post '/admin/books/perform_sav_import'

      expect(response).to redirect_to(new_sav_import_admin_books_path)
      expect(flash[:alert]).to eq('Veuillez sélectionner un fichier csv.')
    end
  end

  describe "alerte 'Renvoyé le' sur la fiche de suivi" do
    it 'apparaît sous le livre une fois le renvoi importé' do
      post '/admin/books/perform_sav_import', params: { csv_file: csv_upload_with("05/08/2026,#{support_module.id},not_received\n") }

      get "/admin/child_supports/#{child.child_support.id}/edit?r=true"

      expect(response.body).to include('Renvoyé le 05/08/2026')
    end
  end
end
