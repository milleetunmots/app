ActiveAdmin.register_page "Module" do

  menu priority: 12, parent: "Programmer des envois"

  content do

    form action: admin_message_program_sms_path, method: :post, id: "sms-form" do |f|
      f.input :authenticity_token, type: :hidden, name: :authenticity_token, value: form_authenticity_token

      label "Date de démarrage"
      div class: "datetime-container" do
        input type: "text", name: "planned_date", class: "datepicker hasDatePicker", style: "margin-right: 20px;", value: Date.today
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

  page_action :recipients do
    results = (
      Parent.where("unaccent(CONCAT(first_name, last_name)) ILIKE unaccent(?)", "%#{params[:term]}%").decorate +
      Tag.where("unaccent(name) ILIKE unaccent(?)", "%#{params[:term]}%").decorate +
      Group.where("unaccent(name) ILIKE unaccent(?)", "%#{params[:term]}%").decorate
    ).map do |result|
      {
        id: "#{result.object.class.name.underscore}.#{result.id}",
        name: result.name,
        type: result.object.class.name.underscore,
        icon: result.icon_class,
        html: result.as_autocomplete_result
      }
    end

    render json: {
      results: results
    }
  end

  page_action :module_to_send do
    results =
      SupportModule.where("unaccent(name) ILIKE unaccent(?)", "%#{params[:term]}%").decorate
        .map do |result|
        {
          id: "#{result.object.class.name.underscore}.#{result.id}",
          name: result.name
        }
      end

    render json: {
      results: results
    }
  end

end
