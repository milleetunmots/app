require 'rails_helper'

RSpec.describe 'Admin book shipment date authorization', type: :request do
  let!(:book) { FactoryBot.create(:book) }
  let(:date_params) { { date: 45.days.from_now.to_date.iso8601 } }

  before { sign_in admin_user }

  context 'as a super_admin' do
    let!(:admin_user) { FactoryBot.create(:admin_user, user_role: 'super_admin') }

    it 'affiche le bandeau des dates de renvoi' do
      get '/admin/books'

      expect(response.body).to include('book-shipment-date-save')
    end

    it 'affiche le lien de gestion du SAV' do
      get '/admin/books'

      expect(response.body).to include('Gestion du SAV')
    end

    it "autorise la création d'une date d'envoi" do
      expect do
        post '/admin/books/upsert_shipment_date', params: date_params
      end.to change(BookShipmentDate, :count).by(1)
    end
  end

  context 'as a contributor' do
    let!(:admin_user) { FactoryBot.create(:admin_user, user_role: 'contributor') }

    it 'affiche le bandeau des dates de renvoi' do
      get '/admin/books'

      expect(response.body).to include('book-shipment-date-save')
    end

    it 'affiche le lien de gestion du SAV' do
      get '/admin/books'

      expect(response.body).to include('Gestion du SAV')
    end

    it "autorise la création d'une date d'envoi" do
      expect do
        post '/admin/books/upsert_shipment_date', params: date_params
      end.to change(BookShipmentDate, :count).by(1)
    end
  end

  context 'as a reader' do
    let!(:admin_user) { FactoryBot.create(:admin_user, user_role: 'reader') }

    it "n'affiche pas le bandeau des dates de renvoi" do
      get '/admin/books'

      expect(response.body).not_to include('book-shipment-dates-banner')
      expect(response.body).not_to include('Gestion SAV')
      expect(response.body).not_to include('Gestion du SAV')
    end

    it "n'autorise pas la création d'une date d'envoi" do
      expect do
        post '/admin/books/upsert_shipment_date', params: date_params
      end.not_to change(BookShipmentDate, :count)

      expect(response).to redirect_to(admin_children_url)
    end

    it "n'autorise pas l'accès au formulaire d'import SAV" do
      get '/admin/books/new_sav_import'

      expect(response).to redirect_to(admin_children_url)
    end

    it "n'autorise pas l'import SAV" do
      expect(Book::SavImportService).not_to receive(:new)

      post '/admin/books/perform_sav_import'

      expect(response).to redirect_to(admin_children_url)
    end
  end
end
