require 'rails_helper'

RSpec.describe 'Rack::Attack login throttling', :rack_attack, type: :request do
  def post_login(email: 'nobody@example.com', ip: '1.2.3.4')
    post '/admin/login',
         params: { admin_user: { email: email, password: 'wrong-password' } },
         headers: { 'REMOTE_ADDR' => ip }
  end

  describe 'throttle par IP' do
    # seuil volontairement haut : une IP est partagée par tout un bureau
    it 'renvoie 429 au-delà de 15 tentatives depuis la même IP' do
      15.times { |i| post_login(email: "user#{i}@example.com", ip: '9.9.9.9') }
      expect(response).not_to have_http_status(:too_many_requests)

      post_login(email: 'user15@example.com', ip: '9.9.9.9')
      expect(response).to have_http_status(:too_many_requests)
      expect(response.headers['Retry-After']).to be_present
    end

    it 'laisse passer plusieurs personnes derrière la même IP de bureau' do
      5.times { |i| post_login(email: "collegue#{i}@example.com", ip: '9.9.9.9') }
      expect(response).not_to have_http_status(:too_many_requests)
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

  describe 'contournement par le format de l’URL' do
    it 'throttle aussi /admin/login.json' do
      6.times do
        post '/admin/login.json',
             params: { admin_user: { email: 'nobody@example.com', password: 'wrong-password' } },
             headers: { 'REMOTE_ADDR' => '198.51.100.4' }
      end
      expect(response).to have_http_status(:too_many_requests)
    end

    it 'throttle aussi /admin/two_factor/verify.json' do
      11.times do
        post '/admin/two_factor/verify.json',
             params: { otp_code: '000000' },
             headers: { 'REMOTE_ADDR' => '198.51.100.5' }
      end
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe 'traçabilité' do
    it 'journalise la règle déclenchée' do
      allow(Rails.logger).to receive(:warn)
      6.times { post_login(ip: '203.0.113.9') }
      expect(Rails.logger).to have_received(:warn).with(/\[rack-attack\] throttled rule=login/).at_least(:once)
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

  describe 'throttle de la saisie du code 2FA' do
    def post_code(ip:)
      post '/admin/two_factor/verify',
           params: { otp_code: '000000' },
           headers: { 'REMOTE_ADDR' => ip }
    end

    it 'renvoie 429 au-delà de 10 requêtes depuis la même IP' do
      10.times { post_code(ip: '9.9.9.10') }
      expect(response).not_to have_http_status(:too_many_requests)

      post_code(ip: '9.9.9.10')
      expect(response).to have_http_status(:too_many_requests)
    end

    it 'couvre aussi le renvoi de code' do
      10.times { post '/admin/two_factor/resend', headers: { 'REMOTE_ADDR' => '9.9.9.11' } }
      post '/admin/two_factor/resend', headers: { 'REMOTE_ADDR' => '9.9.9.11' }
      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
