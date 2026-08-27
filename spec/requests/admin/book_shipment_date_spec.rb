require 'rails_helper'

RSpec.describe 'Admin book shipment dates', type: :request do
  let!(:admin_user) { FactoryBot.create(:admin_user, user_role: 'contributor') }

  before { sign_in admin_user }

  describe 'POST /admin/books/upsert_shipment_date' do
    let!(:first) { BookShipmentDate.create!(date: Date.current + 10.days) }
    let!(:following) { BookShipmentDate.create!(date: Date.current + 80.days) }

    it 'shifts the following date when the first one changes' do
      new_date = Date.current + 20.days

      post '/admin/books/upsert_shipment_date', params: { id: first.id, position: 0, date: new_date.iso8601 }

      expect(response).to have_http_status(:ok)
      expect(first.reload.date).to eq(new_date)
      expect(following.reload.date).to eq(BookShipmentDate.cycle_after(new_date))
    end

    it 'returns the following date so the banner can refresh it' do
      new_date = Date.current + 20.days

      post '/admin/books/upsert_shipment_date', params: { id: first.id, position: 0, date: new_date.iso8601 }

      body = response.parsed_body
      expect(body['id']).to eq(first.id)
      expect(body['following']).to eq(
        'id' => following.id,
        'date' => BookShipmentDate.cycle_after(new_date).iso8601
      )
    end

    it 'leaves the first date alone when the second one changes' do
      new_date = Date.current + 90.days

      post '/admin/books/upsert_shipment_date', params: { id: following.id, position: 1, date: new_date.iso8601 }

      expect(following.reload.date).to eq(new_date)
      expect(first.reload.date).to eq(Date.current + 10.days)
      expect(response.parsed_body['following']).to be_nil
    end

    it 'rejects a past date without touching the following one' do
      post '/admin/books/upsert_shipment_date', params: { id: first.id, position: 0, date: (Date.current - 1.day).iso8601 }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['errors']).to include('La date de renvoi ne peut pas être dans le passé.')
      expect(first.reload.date).to eq(Date.current + 10.days)
      expect(following.reload.date).to eq(Date.current + 80.days)
    end
  end
end
