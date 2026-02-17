ActiveAdmin.register ScheduledCall do
  menu label: 'RDV Calendly', priority: 15, if: -> { current_admin_user.email.in?(ENV['BETA_TEST_CALLERS_EMAIL'].split) }

  config.sort_order = 'scheduled_at'

  actions :all, except: %i[new edit create destroy]

  includes :admin_user, :child_support, :parent

  scope(:all, group: :all)
  scope(:mine, group: :supporter) { |scope| scope.where(admin_user: current_admin_user) }
  scope(:scheduled, group: :status) { |scope| scope.scheduled }
  scope(:canceled, group: :status) { |scope| scope.canceled }
  scope(:upcoming, default: true, group: :time) { |scope| scope.upcoming }

  filter :scheduled_at
  filter :status, as: :select, collection: ScheduledCall::STATUSES
  filter :call_session, as: :select, collection: (0..3).map { |i| ["Appel #{i}", i] }
  filter :admin_user, if: proc { !current_admin_user.caller? && !current_admin_user.animator? }
  filter :child_support_id
  filter :invitee_name
  filter :invitee_email
  filter :created_at

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index download_links: proc { current_admin_user.can_export_data? } do
    id_column
    column :scheduled_at
    column :status do |scheduled_call|
      status_tag scheduled_call.scheduled? ? 'RDV pris' : 'RDV annulé', class: scheduled_call.scheduled? ? 'ok' : 'error'
    end
    column :call_session do |scheduled_call|
      "Appel #{scheduled_call.call_session}" if scheduled_call.call_session
    end
    column :admin_user
    column :child_support
    column :parent do |scheduled_call|
      link_to scheduled_call.parent.decorate.name, admin_parent_path(scheduled_call.parent) if scheduled_call.parent
    end
    column :invitee_name
    column :duration_minutes
    column :created_at
    actions
  end

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :id
      row :status do |scheduled_call|
        status_tag scheduled_call.scheduled? ? 'RDV pris' : 'RDV annulé', class: scheduled_call.scheduled? ? 'ok' : 'error'
      end
      row :scheduled_at
      row :duration_minutes
      row :call_session do |scheduled_call|
        "Appel #{scheduled_call.call_session}" if scheduled_call.call_session
      end
      row :event_type_name
      row :admin_user
      row :child_support
      row :parent do |scheduled_call|
        link_to scheduled_call.parent.decorate.name, admin_parent_path(scheduled_call.parent) if scheduled_call.parent
      end
      row :invitee_name
      row :invitee_email
      row :invitee_comment
      row :canceled_at
      row :cancellation_reason
      row :calendly_event_uri
      row :calendly_invitee_uri
      row :event_type_uri
      row :created_at
      row :updated_at
    end
  end

  # ---------------------------------------------------------------------------
  # CSV
  # ---------------------------------------------------------------------------

  csv do
    column :id
    column :status
    column :scheduled_at
    column :duration_minutes
    column :call_session
    column :event_type_name
    column(:admin_user) { |sc| sc.admin_user&.name }
    column :child_support_id
    column(:parent) { |sc| sc.parent&.decorate&.name }
    column :invitee_name
    column :invitee_email
    column :invitee_comment
    column :canceled_at
    column :cancellation_reason
    column :created_at
  end

  # ---------------------------------------------------------------------------
  # CONTROLLER
  # ---------------------------------------------------------------------------

  controller do
    def scoped_collection
      scope = super
      scope = scope.where(admin_user: current_admin_user) if current_admin_user.caller? || current_admin_user.animator?
      scope
    end
  end
end
