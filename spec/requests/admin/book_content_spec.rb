require 'rails_helper'

RSpec.describe 'Admin book content', type: :request do
  let(:book) { FactoryBot.create(:book, :with_interior_photos, media: FactoryBot.create(:media_image)) }

  before { sign_in admin_user }

  # Tous les rôles qui voient la fiche de suivi doivent pouvoir feuilleter le livre.
  %w[super_admin contributor reader caller animator].each do |role|
    context "as a #{role}" do
      let!(:admin_user) { FactoryBot.create(:admin_user, user_role: role) }

      it 'affiche la couverture et les photos intérieures du livre' do
        get "/admin/books/#{book.id}/read_content"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(CGI.escapeHTML(book.title))
        expect(response.body).to include(book.media.file.blob.filename.to_s)
        book.interior_photos.each do |photo|
          expect(response.body).to include(photo.blob.filename.to_s)
        end
      end

      it 'affiche une card par page et la vue agrandie' do
        get "/admin/books/#{book.id}/read_content"

        html = Capybara.string(response.body)
        expect(html).to have_css('.book-gallery a.book-gallery-card', count: 3)
        expect(html.all('.book-gallery-card-label').map(&:text)).to eq(['Couverture', 'Image 1', 'Image 2'])
        expect(html).to have_css('.book-gallery-card[target]', count: 0)
        expect(html).to have_css('.book-gallery-card img[loading="lazy"]', count: 3)
        expect(html).to have_css('.book-lightbox[hidden]', visible: :all)
      end
    end
  end

  context 'with a book without interior photos' do
    let!(:admin_user) { FactoryBot.create(:admin_user, user_role: 'caller') }
    let(:book) { FactoryBot.create(:book, media: FactoryBot.create(:media_image)) }

    it 'affiche la couverture et un message' do
      get "/admin/books/#{book.id}/read_content"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(book.media.file.blob.filename.to_s)
      expect(response.body).to include('Aucune photo intérieure pour ce livre.')
    end
  end

  # Le droit dédié ne doit pas ouvrir la fiche technique ni la liste des livres.
  context 'as a caller' do
    let!(:admin_user) { FactoryBot.create(:admin_user, user_role: 'caller') }

    it "n'autorise pas l'accès à la fiche du livre" do
      get "/admin/books/#{book.id}"

      expect(response).to redirect_to(admin_children_url)
    end

    it "n'autorise pas l'accès à la liste des livres" do
      get '/admin/books'

      expect(response).to redirect_to(admin_children_url)
    end
  end
end
