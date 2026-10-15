require 'rails_helper'

RSpec.describe 'Admin children — tag « ajouté par accompagnante »', type: :request do
  let(:tag_name) { 'ajoute par accompagnante' }
  let!(:parent) { FactoryBot.create(:parent, first_name: 'Mariama', last_name: 'Diallo') }

  def child_params(overrides = {})
    {
      child: {
        parent1_id: parent.id,
        first_name: 'Aminata',
        last_name: 'Diallo',
        birthdate: (Child.min_birthdate + 10.days).to_s,
        should_contact_parent1: '1',
        available_for_workshops: '1'
      }.merge(overrides)
    }
  end

  def created_child
    Child.find_by(first_name: 'Aminata')
  end

  describe 'POST /admin/children' do
    %w[caller animator contributor super_admin].each do |role|
      context "avec un utilisateur de rôle #{role}" do
        it "crée l'enfant avec le tag" do
          sign_in FactoryBot.create(:admin_user, user_role: role)

          expect { post '/admin/children', params: child_params }.to change(Child, :count).by(1)

          expect(created_child.tag_list).to eq([tag_name])
        end
      end
    end

    context "quand le tag n'existe pas encore" do
      it 'le crée invisible des accompagnantes' do
        sign_in FactoryBot.create(:admin_user, user_role: 'caller')

        post '/admin/children', params: child_params

        tag = Tag.find_by(name: tag_name)
        expect(tag).to be_present
        expect(tag.is_visible_by_callers_and_animators).to be false
      end
    end

    context 'quand le staff a rendu le tag visible' do
      it "crée l'enfant sans erreur de doublon" do
        FactoryBot.create(:tag, name: tag_name, is_visible_by_callers_and_animators: true)
        sign_in FactoryBot.create(:admin_user, user_role: 'caller')

        expect { post '/admin/children', params: child_params }.to change(Child, :count).by(1)

        expect(created_child.tag_list).to eq([tag_name])
        expect(Tag.where(name: tag_name).count).to eq(1)
      end
    end

    context 'avec un prénom vide' do
      it 'ne crée ni enfant ni tagging' do
        sign_in FactoryBot.create(:admin_user, user_role: 'caller')

        expect { post '/admin/children', params: child_params(first_name: '') }
          .not_to(change { [Child.count, ActsAsTaggableOn::Tagging.count] })
      end
    end

    context 'avec un utilisateur de rôle reader' do
      it 'refuse la création' do
        sign_in FactoryBot.create(:admin_user, user_role: 'reader')

        expect { post '/admin/children', params: child_params }
          .not_to(change { [Child.count, ActsAsTaggableOn::Tagging.count] })
      end
    end

    context 'quand un caller envoie tag_list' do
      it 'ignore le tag envoyé et pose celui de création' do
        sign_in FactoryBot.create(:admin_user, user_role: 'caller')

        post '/admin/children', params: child_params(tag_list: ['vip'])

        expect(created_child.tag_list).to eq([tag_name])
      end
    end

    context 'quand un contributor saisit ses propres tags' do
      before { sign_in FactoryBot.create(:admin_user, user_role: 'contributor') }

      it 'conserve ses tags et ajoute celui de création' do
        post '/admin/children', params: child_params(tag_list: ['cohorte-mars'])

        expect(created_child.tag_list).to contain_exactly('cohorte-mars', tag_name)
      end

      it "n'enregistre qu'un seul tagging s'il saisit lui-même le tag de création" do
        post '/admin/children', params: child_params(tag_list: [tag_name])

        expect(created_child.tag_list).to eq([tag_name])
        expect(ActsAsTaggableOn::Tagging.where(taggable: created_child).count).to eq(1)
      end
    end
  end

  describe "Ajout d'un frère / soeur" do
    it "tague l'enfant créé via les paramètres préremplis" do
      caller_user = FactoryBot.create(:admin_user, user_role: 'caller')
      first_child = FactoryBot.create(:child, parent1: parent)
      first_child.child_support.update!(supporter: caller_user)
      sign_in caller_user

      get "/admin/children/#{first_child.id}/add_child"
      expect(response).to redirect_to(%r{/admin/children/new})

      expect { post '/admin/children', params: child_params }.to change(Child, :count).by(1)
      expect(created_child.tag_list).to eq([tag_name])
    end
  end

  describe 'distribution du tag à la famille' do
    let!(:supporter) { FactoryBot.create(:admin_user, user_role: 'caller') }

    before { sign_in supporter }

    context "quand l'enfant est créé pour une famille déjà suivie" do
      let!(:sibling) { FactoryBot.create(:child, parent1: parent, first_name: 'Ibrahima') }

      it 'tague le nouvel enfant, son frère, ses parents et la fiche de suivi' do
        parent2 = FactoryBot.create(:parent)

        post '/admin/children', params: child_params(parent2_id: parent2.id)

        expect(created_child.tag_list).to eq([tag_name])
        expect(sibling.reload.tag_list).to eq([tag_name])
        expect(parent.reload.tag_list).to eq([tag_name])
        expect(parent2.reload.tag_list).to eq([tag_name])
        expect(created_child.child_support.tag_list).to eq([tag_name])
        expect(created_child.child_support_id).to eq(sibling.child_support_id)
      end

      it 'conserve les tags déjà posés sur la famille' do
        parent.update!(tag_list: ['cohorte-mars'])

        post '/admin/children', params: child_params

        expect(parent.reload.tag_list).to contain_exactly('cohorte-mars', tag_name)
      end
    end

    context "quand l'enfant est créé pour une nouvelle famille" do
      it "tague l'enfant, son parent et sa fiche de suivi" do
        post '/admin/children', params: child_params

        expect(created_child.tag_list).to eq([tag_name])
        expect(parent.reload.tag_list).to eq([tag_name])
        expect(created_child.child_support.tag_list).to eq([tag_name])
      end
    end

    context "quand un contributor retire le tag de l'enfant" do
      it 'le retire aussi de la famille' do
        sibling = FactoryBot.create(:child, parent1: parent, first_name: 'Ibrahima')
        post '/admin/children', params: child_params
        sign_in FactoryBot.create(:admin_user, user_role: 'contributor')

        patch "/admin/children/#{created_child.id}", params: { child: { first_name: 'Aminata', tag_list: [''] } }

        expect(created_child.reload.tag_list).to be_empty
        expect(sibling.reload.tag_list).to be_empty
        expect(parent.reload.tag_list).to be_empty
      end
    end
  end

  describe 'PATCH /admin/children/:id' do
    let!(:child) { FactoryBot.create(:child, parent1: parent) }

    it "n'ajoute pas le tag à un enfant existant" do
      sign_in FactoryBot.create(:admin_user, user_role: 'contributor')

      patch "/admin/children/#{child.id}", params: { child: { first_name: 'Aminata B' } }

      expect(child.reload.tag_list).to be_empty
    end

    it 'ne repose pas le tag retiré par un contributor' do
      child.update!(tag_list: [tag_name])
      sign_in FactoryBot.create(:admin_user, user_role: 'contributor')

      patch "/admin/children/#{child.id}", params: { child: { first_name: 'Aminata B', tag_list: [''] } }
      patch "/admin/children/#{child.id}", params: { child: { first_name: 'Aminata C' } }

      expect(child.reload.tag_list).to be_empty
    end
  end

  describe 'visibilité du tag' do
    let!(:supporter) { FactoryBot.create(:admin_user, user_role: 'caller') }
    let!(:child) do
      FactoryBot.create(:child, first_name: 'Zalicempi', parent1: parent, tag_list: [tag_name]).tap do |c|
        c.child_support.update!(supporter: supporter)
      end
    end

    before { Tag.find_by(name: tag_name).update!(is_visible_by_callers_and_animators: false) }

    it "ne l'affiche pas à une accompagnante sur la fiche" do
      sign_in supporter

      get "/admin/children/#{child.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(tag_name)
    end

    it "ne l'affiche pas à une accompagnante dans l'index ni dans le filtre Tags" do
      sign_in supporter

      get '/admin/children'

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Zalicempi')
      expect(response.body).not_to include(tag_name)
    end

    it "l'affiche au staff et permet de filtrer l'index dessus" do
      other_child = FactoryBot.create(:child, first_name: 'Zbobempi', parent1: parent)
      sign_in FactoryBot.create(:admin_user, user_role: 'contributor')

      get '/admin/children', params: { q: { tagged_with_all: [tag_name] } }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Zalicempi')
      expect(response.body).not_to include(other_child.first_name)
    end
  end
end
