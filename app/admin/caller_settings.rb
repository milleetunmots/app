ActiveAdmin.register_page 'Réglages de RDV' do
  menu false

  content do
    render partial: 'admin/admin_user_can_send_automatic_sms_parameters/modal'
    render partial: 'admin/admin_user_can_send_automatic_sms_parameters/settings_panel', locals: { access_to_settings: false }

    group_ids = ChildSupport.all_supported_by(current_admin_user.id).joins(:children).distinct.pluck('children.group_id').compact
    groups = Group.where(id: group_ids)
    existing_overrides = CallSessionDateOverride
                         .where(admin_user: current_admin_user, group_id: group_ids)
                         .index_by { |o| [o.group_id, o.call_session] }

    overrides = groups.flat_map do |group|
      CallSessionDateOverride::CALL_SESSIONS.filter_map do |call_session|
        session_start = group.send("call#{call_session}_start_date")
        session_end = group.send("call#{call_session}_end_date")
        next if session_start.blank? || session_start < Date.current + 4.days

        existing_overrides[[group.id, call_session]] || CallSessionDateOverride.new(
          admin_user: current_admin_user,
          group: group,
          call_session: call_session,
          start_date: session_start,
          end_date: session_end
        )
      end
    end

    overrides = overrides.sort_by do |override|
      override.group.send("call#{override.call_session}_start_date") || override.start_date
    end

    render partial: 'admin/admin_user_can_send_automatic_sms_parameters/call_session_date_overrides',
           locals: { overrides: overrides }
  end

  page_action :toggle_automatic_sms, method: :post do
    current_admin_user.update!(can_send_automatic_sms: !current_admin_user.can_send_automatic_sms)
    notice = current_admin_user.can_send_automatic_sms ? 'SMS de RDV activés' : 'SMS de RDV désactivés'
    redirect_to admin_reglages_path, notice: notice
  end

  page_action :upsert_call_session_date_override, method: :post do
    override = CallSessionDateOverride.find_or_initialize_by(
      admin_user: current_admin_user,
      group_id: params[:group_id],
      call_session: params[:call_session].to_i
    )
    authorize! :manage, override
    override.start_date = params[:start_date]
    override.end_date = params[:end_date]

    if override.save
      render json: { ok: true, id: override.id }
    else
      render json: { ok: false, errors: override.errors.full_messages }, status: :unprocessable_entity
    end
  end

  page_action :reset_call_session_date_override, method: :delete do
    scope = CallSessionDateOverride.where(
      admin_user: current_admin_user,
      group_id: params[:group_id],
      call_session: params[:call_session].to_i
    )
    scope.each { |override| authorize! :manage, override }
    scope.destroy_all
    render json: { ok: true }
  end
end
