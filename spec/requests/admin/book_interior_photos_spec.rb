require 'rails_helper'

RSpec.describe 'Admin book interior photos', type: :request do
  let!(:admin_user) { FactoryBot.create(:admin_user, user_role: 'super_admin') }

  before { sign_in admin_user }

  it 'affiche les photos intérieures sur la fiche du livre' do
    book = FactoryBot.create(:book, :with_interior_photos)

    get "/admin/books/#{book.id}"

    expect(response.body).to include('Photos intérieures')
    book.interior_photos.each do |photo|
      expect(response.body).to include(photo.blob.filename.to_s)
    end
  end

  # Le champ Airtable n'est pas renseigné partout : la fiche doit rester
  # consultable pour un livre sans photo.
  it "affiche la fiche d'un livre sans photo intérieure" do
    book = FactoryBot.create(:book)

    get "/admin/books/#{book.id}"

    expect(response).to have_http_status(:ok)
  end
end
