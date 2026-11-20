require 'rails_helper'
require 'csv'

RSpec.describe 'Admin import des plis non distribués', type: :request do
  let(:csv_path) { Rails.root.join('tmp/undelivered_books_import.csv') }

  after { FileUtils.rm_f(csv_path) }

  def import_undelivered_books
    jean = FactoryBot.create(:parent, letterbox_name: 'Martin', address: '123 rue principale', postal_code: '75001', city_name: 'Mantes-la-jolie')
    FactoryBot.create(:child, parent1: jean, group: FactoryBot.create(:group, expected_children_number: 0), group_status: 'active')
    CSV.open(csv_path, 'wb') do |csv|
      csv << ['Date', 'Titre de livre', 'Prenom', 'Nom', 'Adresse', 'Complément', 'code postal', 'Ville']
      csv << ['02/03/2027', 'La ferme', 'Jean', 'Martin', '123 rue principale', '', '75001', 'Mantes la jolie']
    end
    sign_in FactoryBot.create(:admin_user, user_role: 'contributor', name: 'Claire')
    post '/admin/parents/process_csv', params: { csv_file: Rack::Test::UploadedFile.new(csv_path, 'text/csv') }
  end

  it "renvoie vers le formulaire d'import avec une alerte quand aucun fichier n'est sélectionné" do
    sign_in FactoryBot.create(:admin_user, user_role: 'contributor', name: 'Claire')

    post '/admin/parents/process_csv'

    expect(response).to redirect_to('/admin/parents/upload_undelivered_books_csv')
    expect(flash[:alert]).to eq('Erreur lors de la sélection du fichier csv des plis non livrés.')
  end

  it 'affiche « Fichier traité avec succès! » quand le trio de la demande existe' do
    FactoryBot.create(:media_text_messages_bundle, name: "Demande de vérification d'adresse (PND)",
                                                   body1: 'Vérifiez votre adresse : https://form.typeform.com/to/AbCd#st=xxxxx', body2: nil, body3: nil)

    import_undelivered_books

    expect(flash[:notice]).to eq('Fichier traité avec succès!')
  end

  it "nomme le trio introuvable à l'équipe et ne l'alerte à Rollbar qu'une fois" do
    missing = "Trio introuvable : « Demande de vérification d'adresse (PND) » (clé verification_adresse_pnd), message non envoyé"
    allow(Rollbar).to receive(:error)

    import_undelivered_books

    expect(flash[:alert]).to eq(missing)
    expect(Rollbar).to have_received(:error).once.with('Parent::CheckAdressService', errors: [missing])
  end
end
