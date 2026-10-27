require 'rails_helper'

RSpec.describe 'Pastille des envois bloqués dans le menu', type: :request do
  def menu_entry
    Nokogiri::HTML(response.body).css('#tabs > li').find { |entry| entry.at_css('> a')&.text&.include?('Gestion des envois') }
  end

  def badge
    menu_entry&.at_css('> a .menu-badge')
  end

  describe 'pour un super_admin' do
    before do
      sign_in FactoryBot.create(:admin_user, user_role: 'super_admin')
      FactoryBot.create_list(:blocked_send_attempt, 2, status: 'relaunched')
      FactoryBot.create(:blocked_send_attempt, status: 'archived')
      FactoryBot.create_list(:blocked_send_attempt, 3, status: 'not_blocked')
    end

    [[1, '1'], [12, '12']].each do |pending_count, displayed|
      it "affiche #{displayed} pour #{pending_count} envoi(s) à traiter, sans compter les autres statuts" do
        FactoryBot.create_list(:blocked_send_attempt, pending_count)

        get '/admin/dashboard'

        expect(badge.text).to eq(displayed)
      end
    end

    it "masque la pastille quand aucun envoi n'est à traiter" do
      get '/admin/dashboard'

      expect(menu_entry).to be_present
      expect(badge).to be_nil
    end

    it 'garde les écrans d’envoi sous « Gestion des envois »' do
      FactoryBot.create(:blocked_send_attempt)

      get '/admin/dashboard'

      children = menu_entry.css('ul li > a').map { |link| link.text.strip }
      expect(children).to eq(['Envois bloqués', 'Patterns autorisés', 'Patterns interdits', 'Envois comptabilisés'])
    end

    it 'affiche la pastille sur toutes les pages admin' do
      FactoryBot.create(:blocked_send_attempt)

      get '/admin/tasks'

      expect(badge.text).to eq('1')
    end
  end

  %w[contributor reader caller animator].each do |role|
    it "ne montre ni l'entrée ni le compteur à un #{role}" do
      FactoryBot.create(:blocked_send_attempt)
      sign_in FactoryBot.create(:admin_user, user_role: role)

      get '/admin/dashboard'

      expect(response.body).not_to include('menu-badge')
    end
  end
end
