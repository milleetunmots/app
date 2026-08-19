require 'rails_helper'

RSpec.describe 'Admin médiathèque : erreurs de formulaire', type: :request do
  before { sign_in FactoryBot.create(:admin_user, user_role: 'super_admin') }

  # Media::Video exige un airtable_id (les vidéos viennent de l'import Airtable),
  # champ absent du formulaire admin. `f.semantic_errors` sans argument ne rend
  # que les erreurs sur :base : la création échouait en silence, formulaire
  # re-rendu à l'identique et aucun message pour l'utilisateur.
  it "affiche l'erreur d'un attribut absent du formulaire lors d'une création de vidéo" do
    expect do
      post '/admin/media_videos', params: { media_video: { name: 'testososo', url: 'https://form.typeform.com/to/abc' } }
    end.not_to change(Media::Video, :count)

    expect(response.body).to include('Airtable doit être rempli')
  end
end
