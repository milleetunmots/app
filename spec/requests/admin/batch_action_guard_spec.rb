require 'rails_helper'

# Le `if:` d'une action groupée est évalué côté serveur (lib/active_admin/batch_action_guard.rb) :
# une requête forgée par un rôle qui ne voit pas le bouton est refusée avant le bloc.
RSpec.describe 'Admin garde serveur des actions groupées', type: :request do
  personnel = %w[caller animator]
  hors_coordination = %w[reader caller animator]

  # Rôles qui ne voient pas le bouton, donc refusés côté serveur
  refus = {
    '/admin/children' => {
      add_tags: personnel, remove_tags: personnel, create_support: personnel,
      add_to_group: hors_coordination, quit_group: personnel, reactive_group: personnel,
      create_redirection_url: personnel, addresses_pdf: personnel, mecenat_addresses_pdf: personnel,
      send_address_verification_message: personnel, generate_quit_sms: personnel, excel_export: personnel
    },
    '/admin/child_supports' => {
      add_to_group: hors_coordination, add_tags: personnel, remove_tags: personnel,
      assign_supporter: hors_coordination, remove_call_infos: personnel, select_available_support_module: personnel,
      # noms d'actions avec chiffres : en chaînes pour Naming/VariableNumber
      **%w[check_call_2_4 uncheck_call_2_4].to_h { |action| [action.to_sym, personnel] }
    },
    '/admin/children_support_modules' => { select_module: personnel },
    '/admin/groups' => { support_modules_chosen_excel_export: personnel },
    '/admin/parents' => {
      add_tags: personnel, remove_tags: personnel,
      check_potential_ambassador: personnel, uncheck_potential_ambassador: personnel
    },
    '/admin/media_documents' => { add_tags: personnel, remove_tags: personnel },
    '/admin/media_forms' => { add_tags: personnel, remove_tags: personnel },
    '/admin/media_images' => { add_tags: personnel, remove_tags: personnel },
    '/admin/media_text_messages_bundles' => { add_tags: personnel, remove_tags: personnel },
    '/admin/media_text_messages_bundle_drafts' => { add_tags: personnel, remove_tags: personnel },
    '/admin/media_videos' => { add_tags: personnel, remove_tags: personnel },
    '/admin/support_modules' => { add_tags: personnel, remove_tags: personnel }
  }
  # Sans `if:` : visible de tous, la collection reste filtrée par les droits de lecture
  sans_condition = { '/admin/redirection_urls' => %i[generate_buzz_expert] }

  let(:message_refus) { I18n.t('active_admin.access_denied.message') }

  def forger(chemin, action, ids = [0], inputs = {})
    post "#{chemin}/batch_action", params: {
      batch_action: action, collection_selection: ids, batch_action_inputs: inputs.to_json
    }, headers: { 'HTTP_REFERER' => chemin }
  end

  def utilisateur(role, **attributs)
    FactoryBot.create(:admin_user, user_role: role, **attributs)
  end

  def refusee?
    response.redirect? && flash[:alert] == message_refus
  end

  it 'décide pour chaque action groupée de l’admin quels rôles sont refusés' do
    declarees = refus.transform_values(&:keys).merge(sans_condition) { |_, a, b| a + b }
    existantes = ActiveAdmin.application.namespaces[:admin].resources.each_with_object({}) do |ressource, actions|
      next unless ressource.respond_to?(:batch_actions)

      syms = ressource.batch_actions.map(&:sym) - [:destroy]
      actions[ressource.route_collection_path] = syms if syms.any?
    end

    expect(existantes.transform_values(&:sort)).to eq(declarees.transform_values(&:sort))
  end

  refus.each do |chemin, actions|
    actions.each do |action, roles|
      roles.each do |role|
        it "refuse #{action} sur #{chemin} à un #{role}" do
          sign_in utilisateur(role)

          forger(chemin, action)

          expect(response).to redirect_to('/admin/children')
          expect(flash[:alert]).to eq(message_refus)
        end
      end
    end
  end

  describe 'exports réservés à qui peut exporter les données' do
    it 'refuse l’export Excel des enfants à une contributrice sans droit d’export' do
      sign_in utilisateur('contributor', can_export_data: false)

      forger('/admin/children', :excel_export)

      expect(refusee?).to be(true)
    end

    it "refuse l'export des cohortes à une accompagnante, sans rien exporter" do
      groupe = FactoryBot.create(:group)
      sign_in utilisateur('caller', can_export_data: false)
      expect(Child::ExportBooksV2Service).not_to receive(:new)

      expect { forger('/admin/groups', :support_modules_chosen_excel_export, [groupe.id]) }.not_to change(LogisticExport, :count)
      expect(refusee?).to be(true)
    end

    it 'laisse passer une contributrice qui a le droit d’export' do
      sign_in utilisateur('contributor', can_export_data: true)

      forger('/admin/children', :excel_export, [FactoryBot.create(:child).id])

      expect(refusee?).to be(false)
    end
  end

  describe 'requêtes forgées aux effets sensibles' do
    let(:enfant) { FactoryBot.create(:child, group: FactoryBot.create(:group), group_status: 'active') }

    it "n'envoie aucun SMS de vérification d'adresse pour une accompagnante" do
      sign_in utilisateur('caller')
      expect(ProgramMessageService).not_to receive(:new)

      forger('/admin/children', :send_address_verification_message, [enfant.id])

      expect(refusee?).to be(true)
    end

    it "ne programme aucun SMS de continuation et ne met pas l'enfant en pause pour une animatrice" do
      sign_in utilisateur('animator')
      expect(Child::ProgramQuitMessageService).not_to receive(:new)

      forger('/admin/children', :generate_quit_sms, [enfant.id])

      expect(refusee?).to be(true)
      expect(enfant.reload.group_status).to eq('active')
    end

    it "ne change pas la cohorte d'un enfant depuis les fiches de suivi pour un reader" do
      sans_cohorte = FactoryBot.create(:child)
      groupe = FactoryBot.create(:group)
      sign_in utilisateur('reader')

      forger('/admin/child_supports', :add_to_group, [sans_cohorte.child_support.id], { I18n.t('activerecord.models.group') => groupe.id })

      expect(refusee?).to be(true)
      expect(sans_cohorte.reload.group_id).to be_nil
    end
  end

  describe 'choix des modules disponibles (2e étape de select_available_support_module)' do
    let(:fiche) { FactoryBot.create(:child).child_support }

    def choisir_modules
      post '/admin/child_supports/perform_selecting_available_support_modules', params: {
        ids: [fiche.id], available_support_module_list: %w[42], back_url: '/admin/child_supports'
      }
    end

    it 'refuse une accompagnante, sans toucher aux modules de la fiche' do
      sign_in utilisateur('caller')

      choisir_modules

      expect(refusee?).to be(true)
      expect(fiche.reload.parent1_available_support_module_list).to be_blank
    end

    it 'refuse aussi le formulaire à une animatrice' do
      sign_in utilisateur('animator')

      get '/admin/child_supports/select_available_support_module'

      expect(refusee?).to be(true)
    end

    it 'enregistre les modules pour une contributrice' do
      sign_in utilisateur('contributor')

      choisir_modules

      expect(fiche.reload.parent1_available_support_module_list).to eq(%w[42])
      expect(fiche.parent2_available_support_module_list).to eq(%w[42])
    end
  end

  describe 'actions autorisées' do
    it 'laisse un reader marquer des parents comme bénévoles potentiels' do
      parent = FactoryBot.create(:parent, is_ambassador: false)
      sign_in utilisateur('reader')

      forger('/admin/parents', :check_potential_ambassador, [parent.id])

      expect(refusee?).to be(false)
      expect(parent.reload.is_ambassador).to be(true)
    end

    it 'laisse la suppression groupée par défaut à un super admin' do
      motif = FactoryBot.create(:allowed_pattern)
      sign_in utilisateur('super_admin')

      forger('/admin/allowed_patterns', :destroy, [motif.id])

      expect(refusee?).to be(false)
      expect(AllowedPattern.exists?(motif.id)).to be(false)
    end
  end
end
