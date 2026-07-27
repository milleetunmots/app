require 'rails_helper'

RSpec.describe 'Rack::Attack login throttling', :rack_attack, type: :request do
  def post_login(email: 'nobody@example.com', ip: '1.2.3.4')
    post '/admin/login',
         params: { admin_user: { email: email, password: 'wrong-password' } },
         headers: { 'REMOTE_ADDR' => ip }
  end

  describe 'throttle par IP' do
    it 'renvoie 429 au-delà de 3 tentatives depuis la même IP' do
      3.times { post_login(ip: '9.9.9.9') }
      expect(response).not_to have_http_status(:too_many_requests)

      post_login(ip: '9.9.9.9')
      expect(response).to have_http_status(:too_many_requests)
      expect(response.headers['Retry-After']).to be_present
    end

    it 'ne throttle pas des IP différentes sous le seuil' do
      6.times { |i| post_login(email: "user#{i}@example.com", ip: "10.0.0.#{i}") }
      expect(response).not_to have_http_status(:too_many_requests)
    end
  end

  describe 'throttle par email' do
    it 'renvoie 429 au-delà de 5 tentatives sur le même email, IP variables' do
      5.times { |i| post_login(email: 'cible@example.com', ip: "172.16.0.#{i}") }
      expect(response).not_to have_http_status(:too_many_requests)

      post_login(email: 'cible@example.com', ip: '172.16.0.200')
      expect(response).to have_http_status(:too_many_requests)
    end

    it 'normalise l’email (casse et espaces)' do
      10.times { |i| post_login(email: 'Cible@Example.com ', ip: "192.168.1.#{i}") }
      post_login(email: 'cible@example.com', ip: '192.168.1.200')
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe 'réponse 429' do
    it 'renvoie un corps FR et un Retry-After' do
      6.times { post_login(ip: '203.0.113.7') }
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include('Trop de tentatives')
      expect(response.headers['Retry-After']).to be_present
    end
  end
end
