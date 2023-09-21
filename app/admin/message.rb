include ProgramMessagesHelper

ActiveAdmin.register_page "Message" do

  menu priority: 12, parent: "Programmer des envois"

  content do

    form action: admin_message_program_sms_path, method: :post, id: "sms-form" do |f|
      f.input :authenticity_token, type: :hidden, name: :authenticity_token, value: form_authenticity_token
      f.input :parent_id, type: :hidden, name: :parent_id, id: :parent_id, value: params[:parent_id]

      label "Date et heure d'envoi du message"
      div class: "datetime-container" do
        input type: "text", name: "planned_date", class: "datepicker hasDatePicker", style: "margin-right: 20px;", value: Date.today
        input type: "time", name: "planned_hour", value: Time.zone.now.strftime("%H:%M")
      end

      div do
        label "Choisissez les destinataires"
        select name: "recipients[]", multiple: "multiple", id: "recipients"
      end

      div do
        label "Url cible"
        select name: "redirection_target", id: "redirection_target"
      end

      div do
        label "Message"
        textarea name: "message"
        small "Variables disponibles: {PRENOM_ENFANT}, {URL}"
      end

      if params[:parent_id].present?
        div do
          label "SMS de petite mission ?"
          select name: "call_goals_sms", id: "call_goals_sms" do
            option 'Non', value: nil
            option 'Appel 1', value: 'call1_goals'
            option 'Appel 2', value: 'call2_goals'
            option 'Appel 3', value: 'call3_goals'
            option 'Appel 4', value: 'call4_goals'
            option 'Appel 5', value: 'call5_goals'
          end
        end
      end

      div do
        label "Image"
        select name: "image_to_send", id: "image_to_send"
      end

      div class: "actions" do
        div class: "action input_action" do
          input type: "submit", value: "Valider"
        end
      end
    end
  end

  page_action :program_sms, method: :post do
    service = ProgramMessageService.new(
      params[:planned_date],
      params[:planned_hour],
      params[:recipients],
      params[:message],
      get_spot_hit_file(params[:image_to_send]),
      params[:redirection_target]
    ).call

    if service.errors.any?
      redirect_back(fallback_location: root_path, alert: service.errors.join("\n"))
    else
      notice = 'Message(s) programmé(s)'
      if params[:call_goals_sms] && params[:call_goals_sms] != "Non"
        call_goals_sms = "#{child_support.send(params[:call_goals_sms])}\n#{params[:message]}"
        child_support.update_column(params[:call_goals_sms], call_goals_sms)
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

  controller do
    def parent
      Parent.find_by(id: params[:parent_id])
    end

    def child_support
      parent.current_child.child_support
    end
  end
end
