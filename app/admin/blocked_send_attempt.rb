ActiveAdmin.register BlockedSendAttempt do
  menu parent: 'Gestion des envois', label: 'Envois bloqués', priority: 1

  actions :index, :show # trace d'audit : ni création, ni édition, ni suppression

  scope :pending, default: true
  scope :relaunched
  scope :not_blocked
  scope :archived
  scope :all

  includes :admin_user

  filter :status, as: :select, collection: -> { BlockedSendAttempt::STATUSES.map { |s| [BlockedSendAttempt.human_attribute_name("status.#{s}"), s] } }
  filter :provider, as: :select, collection: BlockedSendAttempt::PROVIDERS
  filter :kind, as: :select, collection: -> { BlockedSendAttempt::KINDS.map { |k| [BlockedSendAttempt.human_attribute_name("kind.#{k}"), k] } }
  filter :created_at

  index do
    id_column
    column :created_at
    column :admin_user
    column :provider
    column :kind do |attempt|
      blocked_send_attempt_kind_tag(attempt)
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
      next unless attempt.status == 'pending'

      links = []
      links << link_to('Relancer', relaunch_admin_blocked_send_attempt_path(attempt), method: :put) if attempt.replayable?
      links << link_to('Archiver', archive_admin_blocked_send_attempt_path(attempt), method: :put, data: { confirm: blocked_send_attempt_archive_confirm })
      content_tag(:span, safe_join(links), class: 'blocked-send-actions')
    end
  end

  show do
    attributes_table do
      row :created_at
      row :admin_user
      row :provider
      row :kind do |attempt|
        blocked_send_attempt_kind_tag(attempt)
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
      para { blocked_send_attempt_relaunch_warning(resource) }
    end

    if resource.status == 'pending'
      para do
        link_to 'Archiver sans envoyer',
                archive_admin_blocked_send_attempt_path(resource),
                method: :put,
                class: 'button',
                data: { confirm: blocked_send_attempt_archive_confirm }
      end
      para { "L'archivage clôt l'envoi sans l'envoyer : la tâche de l'auteur est close avec la mention « Non relancé »." }
    end
  end

  # Le message de relance est construit dans le helper (plafonné pour ne pas faire
  # déborder le cookie de session) : la member_action tourne dans le contrôleur,
  # qui n'accède pas aux helpers de vue sans cet include explicite.
  controller do
    include ActiveAdmin::BlockedSendAttemptsHelper
  end

  # Un `not_blocked` a déjà été transmis au provider : le relancer créerait un doublon.
  member_action :relaunch, method: :put do
    if resource.status != 'pending'
      redirect_to admin_blocked_send_attempt_path(resource), alert: BlockedSendAttempt::RELAUNCH_REFUSED_MESSAGE
      next
    end

    result = resource.relaunch!(admin_user: current_admin_user)
    errors = result.errors.respond_to?(:full_messages) ? result.errors.full_messages : Array(result.errors)

    if errors.any?
      redirect_to admin_blocked_send_attempt_path(resource), alert: "La relance a échoué : #{errors.to_sentence}"
    else
      redirect_to admin_blocked_send_attempt_path(resource), notice: blocked_send_attempt_relaunch_notice(resource.whitelisted_values)
    end
  end

  member_action :archive, method: :put do
    if resource.archive!(admin_user: current_admin_user).errors.any?
      redirect_to admin_blocked_send_attempt_path(resource), alert: resource.errors.full_messages.to_sentence
    else
      redirect_to admin_blocked_send_attempt_path(resource), notice: "L'envoi a été archivé : le message ne sera pas envoyé."
    end
  end
end
