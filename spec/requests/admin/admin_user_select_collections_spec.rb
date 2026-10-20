require 'rails_helper'

RSpec.describe 'Admin — listes de sélection des admin users', type: :request do
  let!(:caller_user) { FactoryBot.create(:admin_user, name: 'Zoé Caller', user_role: 'caller') }
  let!(:animator_user) { FactoryBot.create(:admin_user, name: 'Awa Animatrice', user_role: 'animator') }
  let!(:disabled_caller) { FactoryBot.create(:admin_user, name: 'Inès Désactivée', user_role: 'caller', is_disabled: true) }
  let!(:contributor) { FactoryBot.create(:admin_user, name: 'Mona Contributrice', user_role: 'contributor') }

  before { sign_in FactoryBot.create(:admin_user, name: 'Bertrand Super', user_role: 'super_admin') }

  def options_of(select_css)
    Nokogiri::HTML(response.body).css("#{select_css} option").reject { |option| option['value'].blank? }.map(&:text)
  end

  describe 'filtres « Accompagnante »' do
    {
      '/admin/children' => 'q[supporter_id_in][]',
      '/admin/child_supports' => 'q[supporter_id_in][]',
      '/admin/events_text_messages' => 'q[parent_current_child_supporter_id_in][]',
      '/admin/sent_by_app_text_messages' => 'q[parent_current_child_supporter_id_in][]'
    }.each do |path, filter_name|
      it "ne propose que les accompagnantes actives, triées par nom, sur #{path}" do
        get path

        expect(options_of(%(select[name="#{filter_name}"]))).to eq(['Awa Animatrice', 'Zoé Caller'])
      end
    end
  end

  describe "page d'envoi de messages" do
    def supporter_select
      Nokogiri::HTML(response.body).at_css('select#supporter')
    end

    it 'propose les accompagnantes actives, triées par nom, sans appel au serveur' do
      get '/admin/message'

      expect(options_of('select#supporter')).to eq(['Awa Animatrice', 'Zoé Caller'])
      expect(supporter_select['disabled']).to be_nil
      expect(JSON.parse(supporter_select['data-select2'])).to include('allowClear' => true)
    end

    %w[caller animator].each do |role|
      context "avec un utilisateur de rôle #{role}" do
        let(:supporter) { role == 'caller' ? caller_user : animator_user }

        before { sign_in supporter }

        it 'affiche uniquement son nom, sélectionné et grisé' do
          get '/admin/message'

          expect(options_of('select#supporter')).to eq([supporter.name])
          expect(supporter_select.at_css('option')['selected']).to be_present
          expect(supporter_select['disabled']).to be_present
        end
      end
    end
  end

  describe 'tâches' do
    let(:active_admin_users) { ['Awa Animatrice', 'Bertrand Super', 'Mona Contributrice', 'Zoé Caller'] }

    %w[assignee reporter treated_by].each do |attribute|
      it "propose les utilisateurs actifs, triés par nom, dans le filtre #{attribute}" do
        get '/admin/tasks'

        expect(options_of(%(select[name="q[#{attribute}_id_eq]"]))).to eq(active_admin_users)
      end
    end

    %w[assignee reporter].each do |attribute|
      it "propose les utilisateurs actifs, triés par nom, dans le champ #{attribute} du formulaire" do
        get '/admin/tasks/new'

        expect(options_of("select#task_#{attribute}_id")).to eq(active_admin_users)
      end

      it "garde l'utilisateur désactivé déjà renseigné dans le champ #{attribute} en modification" do
        task = FactoryBot.create(:task, "#{attribute}": disabled_caller)

        get "/admin/tasks/#{task.id}/edit"

        expect(options_of("select#task_#{attribute}_id")).to eq(['Awa Animatrice', 'Bertrand Super', 'Inès Désactivée', 'Mona Contributrice', 'Zoé Caller'])
      end
    end
  end
end
