require 'rails_helper'

RSpec.describe 'Admin — fiche d’un utilisateur', type: :request do
  let(:awa) do
    FactoryBot.create(:admin_user, user_role: 'caller', name: 'Awa Traoré', email: 'awa.traore@1001mots.org',
                                   phone_number: '0698765432', two_factor_enabled: true)
  end
  let(:bintou) { FactoryBot.create(:admin_user, user_role: 'animator', name: 'Bintou Keita') }

  let(:labels_liste_blanche) do
    ['Nom', 'Email', 'Rôle', 'Numéro aircall', 'Téléphone pour la double authentification', 'Double authentification']
  end
  # Le téléphone de la double authentification n'apparaît que sur sa propre fiche.
  let(:labels_fiche_d_un_autre) { labels_liste_blanche - ['Téléphone pour la double authentification'] }

  before do
    awa.update!(aircall_phone_number: '+33612345678')
    awa.update_columns(reset_password_token: 'jeton-de-reinitialisation', reset_password_sent_at: Time.current,
                       otp_code_digest: 'empreinte-otp-secrete', otp_sent_at: Time.current, otp_attempts: 3,
                       current_sign_in_ip: '203.0.113.7', last_sign_in_ip: '203.0.113.8')
  end

  def rows
    Nokogiri::HTML(response.body).css('.attributes_table tr.row')
  end

  def row_labels
    rows.map { |row| row.at_css('th').text.strip }
  end

  def row_value(label)
    rows.find { |row| row.at_css('th').text.strip == label }.at_css('td').text.strip
  end

  def expect_no_sensitive_data
    AdminUser::HIDDEN_ATTRIBUTES.each do |attribute|
      expect(Nokogiri::HTML(response.body).css("tr.row-#{attribute}")).to be_empty
    end
    [awa.encrypted_password, 'jeton-de-reinitialisation', 'empreinte-otp-secrete', '203.0.113.7', '203.0.113.8'].each do |secret|
      expect(response.body).not_to include(secret)
    end
  end

  def expect_no_second_factor_phone
    expect(Nokogiri::HTML(response.body).css('tr.row-phone_number')).to be_empty
    expect(response.body).not_to include('+33698765432')
  end

  describe 'une accompagnante ouvre sa propre fiche' do
    before do
      sign_in awa
      get "/admin/admin_users/#{awa.id}"
    end

    it 'affiche exactement les six lignes de la liste blanche' do
      expect(row_labels).to eq(labels_liste_blanche)
    end

    it 'affiche le tableau dans un panel, comme un show standard' do
      expect(Nokogiri::HTML(response.body).css('.panel .attributes_table')).to be_present
    end

    it 'affiche les valeurs de son compte' do
      expect(row_value('Nom')).to eq('Awa Traoré')
      expect(row_value('Email')).to eq('awa.traore@1001mots.org')
      expect(row_value('Rôle')).to eq('Accompagnante')
      expect(row_value('Numéro aircall')).to eq('+33612345678')
      expect(row_value('Téléphone pour la double authentification')).to eq('+33698765432')
      expect(row_value('Double authentification')).to eq('Oui')
    end

    it 'ne contient aucune donnée chiffrée ni technique' do
      expect_no_sensitive_data
    end

    it 'ne propose ni modification, ni désactivation, ni réactivation' do
      expect(response.body).not_to include(edit_admin_admin_user_path(awa))
      expect(response.body).not_to include('Désactiver le compte')
      expect(response.body).not_to include('Réactiver le compte')
    end
  end

  describe 'une animatrice sans numéro ni double authentification' do
    before do
      sign_in bintou
      bintou.update_columns(aircall_phone_number: nil, phone_number: nil, two_factor_enabled: false)
      get "/admin/admin_users/#{bintou.id}"
    end

    it 'affiche la fiche sans erreur' do
      expect(response).to have_http_status(:ok)
      expect(row_labels).to eq(labels_liste_blanche)
    end

    it 'montre la double authentification désactivée' do
      expect(row_value('Double authentification')).to eq('Non')
    end
  end

  describe 'accès refusé' do
    before { sign_in awa }

    it 'redirige une accompagnante qui ouvre la fiche d’une autre' do
      get "/admin/admin_users/#{bintou.id}"

      expect(response).to redirect_to(admin_children_url)
      expect(flash[:alert]).to be_present
    end

    it 'refuse la modification de sa propre fiche' do
      put "/admin/admin_users/#{awa.id}", params: { admin_user: { name: 'Awa T.' } }

      expect(response).to redirect_to(admin_children_url)
      expect(awa.reload.name).to eq('Awa Traoré')
    end
  end

  %w[contributor reader].each do |role|
    describe "un #{role} ouvre la fiche d’une accompagnante" do
      before do
        sign_in FactoryBot.create(:admin_user, user_role: role)
        get "/admin/admin_users/#{awa.id}"
      end

      it 'affiche les lignes de la liste blanche, sans le téléphone de double authentification' do
        expect(row_labels).to eq(labels_fiche_d_un_autre)
      end

      it 'ne contient aucune donnée chiffrée ni technique' do
        expect_no_sensitive_data
      end

      it 'ne montre pas le téléphone de double authentification' do
        expect_no_second_factor_phone
      end
    end
  end

  describe 'un super_admin ouvre la fiche d’une accompagnante' do
    before do
      sign_in FactoryBot.create(:admin_user, user_role: 'super_admin')
      get "/admin/admin_users/#{awa.id}"
    end

    it 'affiche les lignes d’avant, hors colonnes chiffrées ou techniques' do
      expect(row_labels).to include('Compte désactivé', 'Peut exporter des données', 'Connexions', *labels_fiche_d_un_autre)
    end

    it 'ne contient aucune donnée chiffrée ni technique' do
      expect_no_sensitive_data
    end

    it 'ne montre pas le téléphone de double authentification d’une autre personne' do
      expect_no_second_factor_phone
    end

    it 'propose toujours la modification et la désactivation' do
      expect(response.body).to include(edit_admin_admin_user_path(awa))
      expect(response.body).to include('Désactiver le compte')
    end
  end
end
