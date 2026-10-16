require 'rails_helper'

RSpec.describe 'Connexion en tant qu\'une accompagnante', type: :request do
  let(:clara) { FactoryBot.create(:admin_user, user_role: 'contributor') }
  let(:marie) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let(:paul) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let(:sonia) { FactoryBot.create(:admin_user, user_role: 'animator') }

  let!(:leo) { FactoryBot.create(:child, first_name: 'Léo').tap { |child| child.child_support.update!(supporter: marie) } }
  let!(:nina) { FactoryBot.create(:child, first_name: 'Nina').tap { |child| child.child_support.update!(supporter: paul) } }

  def start_impersonation(target)
    post "/admin/admin_users/#{target.id}/impersonation"
  end

  def stop_impersonation
    delete '/admin/impersonation'
  end

  describe 'POST /admin/admin_users/:id/impersonation' do
    context "quand une coordinatrice se connecte en tant qu'accompagnante" do
      before { sign_in clara }

      it 'ouvre une ligne de journal et redirige vers le tableau de bord' do
        expect { start_impersonation(marie) }.to change(AdminUserImpersonation, :count).by(1)

        expect(response).to redirect_to('/admin')
        expect(AdminUserImpersonation.last).to have_attributes(operator: clara, target: marie, ended_at: nil)
      end

      it 'affiche le tableau de bord de la cible' do
        start_impersonation(marie)
        get '/admin'

        expect(response).to have_http_status(:ok)
      end

      it "montre les enfants de la cible et pas ceux d'une autre accompagnante" do
        start_impersonation(marie)
        get '/admin/children'

        expect(response.body).to include('Léo')
        expect(response.body).not_to include('Nina')
      end

      it "montre tous les enfants quand la cible est une animatrice, qui n'est pas restreinte à ses fiches" do
        start_impersonation(sonia)
        get '/admin/children'

        expect(response.body).to include('Léo')
        expect(response.body).to include('Nina')
      end
    end

    describe 'selon le rôle de l\'opérateur et de la cible' do
      [
        %w[contributor caller],
        %w[contributor animator],
        %w[super_admin caller],
        %w[super_admin animator]
      ].each do |operator_role, target_role|
        it "autorise un #{operator_role} à se connecter en tant que #{target_role}" do
          sign_in FactoryBot.create(:admin_user, user_role: operator_role)
          target = FactoryBot.create(:admin_user, user_role: target_role)

          expect { start_impersonation(target) }.to change(AdminUserImpersonation, :count).by(1)
          expect(response).to redirect_to('/admin')
        end
      end
    end

    context "quand l'opérateur n'a pas le droit de se connecter en tant qu'un autre compte" do
      %w[reader caller animator].each do |role|
        it "refuse un #{role} sans rien enregistrer" do
          sign_in FactoryBot.create(:admin_user, user_role: role)

          expect { start_impersonation(marie) }.not_to change(AdminUserImpersonation, :count)

          expect(flash[:alert]).to eq('Action non autorisée')
        end
      end

      it 'laisse la session sur le compte de la personne qui a tenté' do
        sign_in paul

        start_impersonation(marie)
        get '/admin/children'

        expect(response.body).to include('Nina')
        expect(response.body).not_to include('Léo')
      end
    end

    context 'quand on ne peut pas se connecter en tant que la cible' do
      {
        'un lecteur actif' => { user_role: 'reader', is_disabled: false },
        'un super_admin' => { user_role: 'super_admin', is_disabled: false },
        'un contributor' => { user_role: 'contributor', is_disabled: false },
        'une accompagnante désactivée' => { user_role: 'caller', is_disabled: true },
        'une animatrice désactivée' => { user_role: 'animator', is_disabled: true }
      }.each do |label, attributes|
        it "refuse #{label} sans rien enregistrer" do
          sign_in clara
          target = FactoryBot.create(:admin_user, **attributes)

          expect { start_impersonation(target) }.not_to change(AdminUserImpersonation, :count)

          expect(flash[:alert]).to eq('Impossible de se connecter en tant que ce compte')
        end
      end
    end

    context 'quand une connexion en tant que est déjà en cours' do
      before do
        sign_in clara
        start_impersonation(marie)
      end

      it "refuse de se connecter en tant qu'une seconde personne" do
        expect { start_impersonation(paul) }.not_to change(AdminUserImpersonation, :count)

        expect(flash[:alert]).to eq("Revenez d'abord à votre propre compte")
      end

      it 'continue de montrer la vue de la première cible' do
        start_impersonation(paul)
        get '/admin/children'

        expect(response.body).to include('Léo')
        expect(response.body).not_to include('Nina')
      end

      it 'garde une seule ligne de journal, celle de la première cible' do
        start_impersonation(paul)

        expect(AdminUserImpersonation.pluck(:target_id)).to eq([marie.id])
      end
    end

    context "quand personne n'est connecté" do
      it 'redirige vers la page de connexion sans rien enregistrer' do
        expect { start_impersonation(marie) }.not_to change(AdminUserImpersonation, :count)

        expect(response).to redirect_to('/admin/login')
      end
    end
  end

  describe 'DELETE /admin/impersonation' do
    before { sign_in clara }

    context 'quand une connexion en tant que est en cours' do
      before { start_impersonation(marie) }

      it 'renseigne la fin de la ligne de journal et redirige vers le tableau de bord' do
        stop_impersonation

        expect(response).to redirect_to('/admin')
        expect(AdminUserImpersonation.last.ended_at).to be_within(5.seconds).of(Time.current)
      end

      it "rend la vue de l'opérateur" do
        stop_impersonation
        get '/admin/children'

        expect(response.body).to include('Léo')
        expect(response.body).to include('Nina')
      end

      it 'permet ensuite une nouvelle connexion en tant que, dans une ligne distincte' do
        stop_impersonation

        expect { start_impersonation(paul) }.to change(AdminUserImpersonation, :count).by(1)
      end
    end

    context "quand aucune connexion en tant que n'est en cours" do
      it 'redirige sans erreur ni écriture' do
        expect { stop_impersonation }.not_to change(AdminUserImpersonation, :count)

        expect(response).to redirect_to('/admin')
      end
    end
  end
end
