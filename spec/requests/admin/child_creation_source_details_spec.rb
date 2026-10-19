xrequire 'rails_helper'

RSpec.describe 'Admin children — détail de source « Ajouté par 1001mots »', type: :request do
  let(:admin_details) { ChildrenSource::ADMIN_CREATION_DETAILS }
  let!(:parent) { FactoryBot.create(:parent, first_name: 'Mariama', last_name: 'Diallo') }
  let!(:source) { FactoryBot.create(:source, channel: 'pmi', department: 75) }

  def child_params(source_attributes = {}, overrides = {})
    {
      child: {
        parent1_id: parent.id,
        first_name: 'Aminata',
        last_name: 'Diallo',
        birthdate: (Child.min_birthdate + 10.days).to_s,
        should_contact_parent1: '1',
        available_for_workshops: '1',
        children_source_attributes: { source_id: source.id }.merge(source_attributes)
      }.merge(overrides)
    }
  end

  def created_child
    Child.find_by(first_name: 'Aminata')
  end

  describe 'POST /admin/children' do
    %w[caller animator contributor super_admin].each do |role|
      context "avec un utilisateur de rôle #{role}" do
        it "pose le détail de source sur l'enfant créé" do
          sign_in FactoryBot.create(:admin_user, user_role: role)

          expect { post '/admin/children', params: child_params }.to change(Child, :count).by(1)

          expect(created_child.children_source_details).to eq(admin_details)
          expect(created_child.source).to eq(source)
        end
      end
    end

    context 'avec un contributor' do
      before { sign_in FactoryBot.create(:admin_user, user_role: 'contributor') }

      it 'conserve le détail qu’il a saisi' do
        post '/admin/children', params: child_params(details: 'Salon petite enfance')

        expect(created_child.children_source_details).to eq('Salon petite enfance')
      end

      it 'pose la valeur quand il vide le détail' do
        post '/admin/children', params: child_params(details: '')

        expect(created_child.children_source_details).to eq(admin_details)
      end
    end

    %w[caller animator].each do |role|
      context "quand un #{role} envoie un détail" do
        it 'ignore le détail envoyé et pose la valeur' do
          sign_in FactoryBot.create(:admin_user, user_role: role)

          post '/admin/children', params: child_params(details: 'Recommandé par une amie')

          expect(created_child.children_source_details).to eq(admin_details)
        end
      end
    end

    context 'avec un prénom vide' do
      it 'ne crée ni enfant ni détail de source' do
        sign_in FactoryBot.create(:admin_user, user_role: 'caller')

        expect { post '/admin/children', params: child_params({}, first_name: '') }
          .not_to(change { [Child.count, ChildrenSource.count] })
      end
    end

    context 'sans source' do
      it "refuse la création et n'enregistre rien" do
        sign_in FactoryBot.create(:admin_user, user_role: 'caller')

        expect { post '/admin/children', params: child_params(source_id: '') }
          .not_to(change { [Child.count, ChildrenSource.count] })
        expect(response.body).to include('doit exister')
      end
    end

    context 'avec un utilisateur de rôle reader' do
      it 'refuse la création' do
        sign_in FactoryBot.create(:admin_user, user_role: 'reader')

        expect { post '/admin/children', params: child_params }
          .not_to(change { [Child.count, ChildrenSource.count] })
      end
    end
  end

  describe "Ajout d'un frère / soeur" do
    it 'pose la valeur sans reprendre le détail du frère' do
      caller_user = FactoryBot.create(:admin_user, user_role: 'caller')
      first_child = FactoryBot.create(:child, first_name: 'Ibrahima', parent1: parent)
      ChildrenSource.create!(child: first_child, source: source, details: 'Instagram')
      first_child.child_support.update!(supporter: caller_user)
      sign_in caller_user

      get "/admin/children/#{first_child.id}/add_child"
      expect(response).to redirect_to(%r{/admin/children/new})

      post '/admin/children', params: child_params

      expect(created_child.children_source_details).to eq(admin_details)
      expect(first_child.reload.children_source_details).to eq('Instagram')
    end
  end

  # ActiveAdmin rend `value` avant `name` : on isole la balise par son `name`.
  def details_input
    response.body[/<input[^>]*name="child\[children_source_attributes\]\[details\]"[^>]*>/]
  end

  describe 'formulaire de création' do
    {
      'caller' => true,
      'animator' => true,
      'contributor' => false,
      'super_admin' => false
    }.each do |role, greyed|
      context "avec un utilisateur de rôle #{role}" do
        it "pré-remplit le détail, #{greyed ? 'grisé' : 'modifiable'}" do
          sign_in FactoryBot.create(:admin_user, user_role: role)

          get '/admin/children/new'

          expect(details_input).to be_present
          expect(details_input).to include(%(value="#{admin_details}"))
          expect(details_input.include?('disabled')).to eq(greyed)
        end
      end
    end

    it 'ré-affiche la valeur après un refus pour source absente' do
      sign_in FactoryBot.create(:admin_user, user_role: 'caller')

      post '/admin/children', params: child_params(source_id: '')

      expect(details_input).to include(%(value="#{admin_details}"))
      expect(details_input).to include('disabled')
    end
  end

  describe 'modification' do
    let(:other_source) { FactoryBot.create(:source, channel: 'caf', department: 93) }
    let!(:child) { FactoryBot.create(:child, first_name: 'Ibrahima', parent1: parent) }
    let!(:children_source) { ChildrenSource.create!(child: child, source: source, details: 'Instagram') }
    let(:supporter) { FactoryBot.create(:admin_user, user_role: role) }

    before { child.child_support.update!(supporter: supporter) }

    %w[caller animator].each do |role|
      context "avec un utilisateur de rôle #{role}" do
        let(:role) { role }

        before { sign_in supporter }

        it 'affiche le détail existant grisé' do
          get "/admin/children/#{child.id}/edit"

          expect(details_input).to include('value="Instagram"')
          expect(details_input).to include('disabled')
        end

        it 'ignore un détail forgé tout en enregistrant les autres champs' do
          patch "/admin/children/#{child.id}",
                params: { child: { first_name: 'Ibrahima B', children_source_attributes: { id: children_source.id, details: 'Autre' } } }

          expect(child.reload.first_name).to eq('Ibrahima B')
          expect(child.children_source_details).to eq('Instagram')
        end

        it 'peut changer la source sans changer le détail' do
          patch "/admin/children/#{child.id}",
                params: { child: { children_source_attributes: { id: children_source.id, source_id: other_source.id } } }

          expect(child.reload.source).to eq(other_source)
          expect(child.children_source_details).to eq('Instagram')
        end
      end
    end

    context 'avec un contributor' do
      let(:role) { 'contributor' }

      before { sign_in supporter }

      it 'affiche le détail modifiable' do
        get "/admin/children/#{child.id}/edit"

        expect(details_input).to include('value="Instagram"')
        expect(details_input).not_to include('disabled')
      end

      it 'modifie le détail' do
        patch "/admin/children/#{child.id}",
              params: { child: { children_source_attributes: { id: children_source.id, details: 'Salon petite enfance' } } }

        expect(child.reload.children_source_details).to eq('Salon petite enfance')
      end
    end
  end

  describe 'lecture' do
    let!(:admin_child) { FactoryBot.create(:child, first_name: 'Zalicempi', parent1: parent) }
    let!(:public_child) { FactoryBot.create(:child, first_name: 'Zbobempi', parent1: parent) }

    before do
      ChildrenSource.create!(child: admin_child, source: source, details: admin_details)
      ChildrenSource.create!(child: public_child, source: source, details: 'Instagram')
      sign_in FactoryBot.create(:admin_user, user_role: 'contributor')
    end

    it 'propose la valeur dans le filtre « Précisions sur l’origine »' do
      get '/admin/children'

      expect(response.body).to include(%(<option value="#{admin_details}">))
    end

    it 'ne retourne que les enfants portant la valeur quand on filtre dessus' do
      get '/admin/children', params: { q: { source_details_matches_any: [admin_details] } }

      expect(response.body).to include('Zalicempi')
      expect(response.body).not_to include('Zbobempi')
    end

    it "l'affiche sur la fiche de l'enfant" do
      get "/admin/children/#{admin_child.id}"

      expect(response.body).to include(admin_details)
    end

    it "l'exporte dans la colonne du CSV" do
      sign_in FactoryBot.create(:admin_user, user_role: 'super_admin', can_export_data: true)

      get '/admin/children.csv', params: { scope: 'all' }

      expect(response.body).to include(admin_details)
    end
  end
end
