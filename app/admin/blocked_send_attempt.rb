ActiveAdmin.register BlockedSendAttempt do
  menu parent: 'Gestion des envois', label: 'Envois bloqués', priority: 1

  actions :index, :show # trace d'audit : ni création, ni édition, ni suppression

  scope :pending, default: true, label: 'À traiter'
  scope :relaunched, label: 'Relancés'
  scope :not_blocked, label: 'Surveillance'
  scope :all, label: 'Tous'

  filter :status, as: :select, collection: -> { BlockedSendAttempt::STATUSES.map { |s| [BlockedSendAttempt.human_attribute_name("status.#{s}"), s] } }
  filter :provider, as: :select, collection: BlockedSendAttempt::PROVIDERS
  filter :kind, as: :select, collection: -> { BlockedSendAttempt::KINDS.map { |k| [BlockedSendAttempt.human_attribute_name("kind.#{k}"), k] } }
  filter :created_at

  index do
    id_column
    column :created_at
    column :provider
    column :kind do |attempt|
      BlockedSendAttempt.human_attribute_name("kind.#{attempt.kind}")
    end
    column :detected_values do |attempt|
      attempt.detected_values.join(', ')
    end
    column :message_body do |attempt|
      truncate(attempt.message_body, length: 80)
    end
    column :status do |attempt|
      BlockedSendAttempt.human_attribute_name("status.#{attempt.status}")
    end
    column '' do |attempt|
      link_to 'Relancer', relaunch_admin_blocked_send_attempt_path(attempt), method: :put if attempt.status == 'pending' && attempt.replayable?
    end
  end

  show do
    attributes_table do
      row :created_at
      row :provider
      row :kind do |attempt|
        BlockedSendAttempt.human_attribute_name("kind.#{attempt.kind}")
      end
      row :status do |attempt|
        BlockedSendAttempt.human_attribute_name("status.#{attempt.status}")
      end
      row :resolved_at
      row :detected_values do |attempt|
        attempt.detected_values.join(', ')
      end
      row :message_body do |attempt|
        simple_format(attempt.message_body)
      end
      row :replay_params do |attempt|
        if attempt.replayable?
          pre JSON.pretty_generate(attempt.replay_params)
        else
          "Envoi automatique sans paramètres de relance : cette tentative n'est pas relançable."
        end
      end
    end

    if resource.status == 'pending' && resource.replayable?
      para do
        link_to 'Relancer cet envoi', relaunch_admin_blocked_send_attempt_path(resource), method: :put, class: 'button'
      end
    end
  end

  # Un `not_blocked` a déjà été transmis au provider : le relancer créerait un doublon.
  member_action :relaunch, method: :put do
    if resource.status != 'pending'
      redirect_to admin_blocked_send_attempt_path(resource), alert: 'Seules les tentatives à traiter peuvent être relancées.'
      next
    end

    result = resource.relaunch!
    errors = result.errors.respond_to?(:full_messages) ? result.errors.full_messages : Array(result.errors)

    if errors.any?
      redirect_to admin_blocked_send_attempt_path(resource), alert: "La relance a échoué : #{errors.to_sentence}"
    else
      redirect_to admin_blocked_send_attempt_path(resource), notice: "L'envoi a été relancé."
    end
  end
end
