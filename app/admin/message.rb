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
      redirect_back(fallback_location: root_path, notice: "Message(s) programmé(s)")
    end
  end

  page_action :recipients do
    render json: { results: get_recipients(params[:term]) } unless params[:parent_id]
    parent = Parent.find_by(id: params[:parent_id])

    render json: {
      results: parent ? get_recipients(params[:term], parent.decorate) : []
    }
  end

  page_action :redirection_targets do
    render json: { results: get_redirection_targets(params[:term]) } unless params[:parent_id]
    parent = Parent.find_by(id: params[:parent_id])

    render json: {
      results: parent ? get_redirection_targets(params[:term], parent.decorate) : []
    }
  end

  page_action :image_to_send do
    render json: {
      results: get_image_to_send(params[:term])
    }
  end
end
