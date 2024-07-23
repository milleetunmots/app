include ProgramMessagesHelper

ActiveAdmin.register_page 'Message' do
  menu priority: 12, parent: 'Programmer des envois'

  content do
    form action: admin_message_program_sms_path, method: :post, id: 'sms-form' do |f|
      f.input :authenticity_token, type: :hidden, name: :authenticity_token, value: form_authenticity_token
      f.input :parent_id, type: :hidden, name: :parent_id, id: :parent_id, value: params[:parent_id]
      f.input :supporter_id, type: :hidden, name: :supporter_id, id: :supporter_id, value: current_admin_user.caller? ? current_admin_user.id : nil

      label "Date et heure d'envoi du message"
      div class: 'datetime-container' do
        input type: 'text', name: 'planned_date', class: 'datepicker hasDatePicker', style: 'margin-right: 20px;', value: Time.zone.today
        input type: 'time', name: 'planned_hour', value: Time.zone.now.strftime('%H:%M')
      end

      div do
        label 'Choisissez les destinataires'
        select name: 'recipients[]', multiple: 'multiple', id: 'recipients'
      end

      div do
        label 'Statuts des enfants'
        select name: 'group_status[]', multiple: 'multiple', id: 'message_group_status'
      end

      div do
        label 'Responsable'
        select name: 'supporter', id: 'supporter'
      end

      if params[:parent_id].present?
        div do
          label 'SMS de petite mission ?'
          select name: 'call_goals_sms', id: 'call_goals_sms' do
            option 'Non', value: nil
            option 'Appel 0', value: 'call0_goals'
            option 'Appel 1', value: 'call1_goals'
            option 'Appel 2', value: 'call2_goals'
            option 'Appel 3', value: 'call3_goals'
            option 'Appel 3 - PARLER', value: 'call3_goals_speaking'
            option 'Appel 3 - OBSERVER', value: 'call3_goals_observing'
            option 'Appel 4', value: 'call4_goals'
            option 'Appel 5', value: 'call5_goals'
          end
        end
      end

      div do
        label 'Url cible'
        select name: 'redirection_target', id: 'redirection_target'
      end

      div do
        label 'Message'
        textarea name: 'message'
        small 'Variables disponibles: {PRENOM_ENFANT}, {URL}'
      end

      div id: 'call_goal_div' do
        label 'Petite mission'
        textarea name: 'call_goal' do
          child_support_call3_goals(params[:child_support_id])
        end
      end

      div id: 'additional_message_div' do
        label 'Message complémentaire'
        textarea name: 'additional_message'
      end

      div do
        label 'Image'
        select name: 'image_to_send', id: 'image_to_send'
      end

      div class: 'actions' do
        div class: 'action input_action' do
          input type: 'submit', value: 'Valider'
        end
      end
    end
  end

  page_action :program_sms, method: :post do
    call_goal =
      if params[:call_goals_sms].in? %w[call3_goals_speaking call3_goals_observing]
        'call3_goals'
      else
        params[:call_goals_sms]
      end
    service = ProgramMessageService.new(
      params[:planned_date],
      params[:planned_hour],
      params[:recipients],
      params[:message],
      get_spot_hit_file(params[:image_to_send]),
      params[:redirection_target],
      false,
      nil,
      current_admin_user.caller? ? current_admin_user.id : params[:supporter],
      params[:group_status]
    ).call

    if service.errors.any?
      redirect_back(fallback_location: root_path, alert: service.errors.join("\n"))
    else
      notice = 'Message(s) programmé(s)'
      if params[:call_goals_sms] && params[:call_goals_sms] != 'Non'
        child_support.update_column("#{call_goal}_sms".to_sym, params[:message])
        notice += '. Et petite mission définie'
      end
      redirect_back(fallback_location: root_path, notice: notice)
    end
  end

  page_action :recipients do
    if params[:parent_id]
      render json: { results: parent ? get_recipients(params[:term], parent.decorate) : [] }
    else
      render json: { results: get_recipients(params[:term]) }
    end
  end

  page_action :redirection_targets do
    if params[:parent_id]
      render json: {
        results: parent ? get_redirection_targets(params[:term], parent.decorate) : []
      }
    else
      render json: { results: get_redirection_targets(params[:term]) }
    end
  end

  page_action :image_to_send do
    render json: {
      results: get_image_to_send(params[:term])
    }
  end

  page_action :supporter do
    if params[:supporter_id]
      render json: { results: current_supporter ? get_supporter(params[:term], current_supporter.decorate) : [] }
    else
      render json: { results: get_supporter(params[:term]) }
    end
  end

  page_action :group_status do
    render json: {
      results: Child::GROUP_STATUS.map do |v|
        {
          id: v,
          text: Child.human_attribute_name("group_status.#{v}"),
          selected: v == 'active'
        }
      end
    }
  end

  controller do
    def parent
      Parent.find_by(id: params[:parent_id])
    end

    def current_supporter
      AdminUser.find_by(id: params[:supporter_id])
    end

    def child_support
      parent.current_child.child_support
    end
  end
end
