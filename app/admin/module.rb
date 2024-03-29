include ProgramMessagesHelper

ActiveAdmin.register_page "Module" do

  menu priority: 12, parent: "Programmer des envois"

  content do
    form action: admin_module_program_module_path, method: :post, id: "sms-form" do |f|
      f.input :authenticity_token, type: :hidden, name: :authenticity_token, value: form_authenticity_token

      label "Date de démarrage"
      div class: "datetime-container" do
        input type: "text", name: "planned_date", class: "datepicker hasDatePicker", style: "margin-right: 20px;", value: Time.zone.today
      end

      div do
        label "Choisissez les destinataires"
        select name: "recipients[]", multiple: "multiple", id: "recipients"
      end

      div do
        label "Choisissez le module à envoyer"
        select name: "module_to_send", id: "module_to_send"
      end

      div class: "actions" do
        div class: "action input_action" do
          input type: "submit", value: "Valider"
        end
      end
    end
  end

  page_action :program_module, method: :post do
    if !Date.parse(params[:planned_date]).tuesday?
      redirect_back(
        fallback_location: root_path,
        alert: "La date de démarrage doit être un mardi"
      )
    elsif Date.parse(params[:planned_date]).past?
      redirect_back(
        fallback_location: root_path,
        alert: "Choisissez une date ultérieure s'il vous plait."
      )
    elsif params[:recipients].nil?
      redirect_back(
        fallback_location: root_path,
        alert: "Choisissez au moins un destinataire s'il vous plait."
      )
    elsif params[:module_to_send].nil?
      redirect_back(
        fallback_location: root_path,
        alert: "Choisissez le module à programmer s'il vous plait."
      )
    else
      redirect_to admin_messages_path(
        planned_date: params[:planned_date],
        recipients: params[:recipients],
        module_to_send: params[:module_to_send]
      )
    end
  end

  page_action :recipients do
    render json: {
      results: get_recipients(params[:term])
    }
  end

  page_action :module_to_send do
    render json: {
      results: get_module(params[:term])
    }
  end
end
