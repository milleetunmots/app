ActiveAdmin.register_page "Messages" do
  menu false

  content do
    messages = retrieve_messages(params[:module_to_send])
    form action: admin_messages_program_module_message_path, method: :post do |f|
      f.input :authenticity_token, type: :hidden, name: :authenticity_token, value: form_authenticity_token
      f.input :recipients, type: :hidden, name: :recipients, value: params[:recipients]

      messages.each_with_index do |support_module_week, week_index|
        div do
          label "Semaine #{week_index + 1}"
          columns do
            support_module_week[1].each_with_index do |message, message_index|
              column do
                div do
                  label "Message #{message_index + 1}"
                  textarea name: "body_#{support_module_week[0]}_#{message[0]}" do
                    message[1][:body]
                  end
                end

                if message[1][:link]
                  div do
                    # label "Url cible #{message_index + 1}"
                    select name: "link_#{support_module_week[0]}_#{message[0]}",
                           value: message[1][:link], hidden: true
                    small "{URL} disponible"
                  end
                end

                div do
                  div class: "datetime-container" do
                    input type: "text",
                          name: "planned_date_#{support_module_week[0]}_#{message[0]}",
                          class: "datepicker hasDatePicker",
                          style: "margin-right: 20px;",
                          value: params[:planned_date]

                    input type: "time",
                          name: "planned_hour_#{support_module_week[0]}_#{message[0]}",
                          value: "12:30"
                  end

                end
              end
            end
          end
        end
        div class: "actions" do
          div class: "action input_action" do
            input type: "submit", value: "Programmer"
          end
        end
      end
    end
  end

  page_action :program_module_message, method: :post do

    recipients = params[:recipients].tr('["]', "").delete(" ").split(",")

    messages = {}
    links = {}
    planned_dates = {}
    planned_hours = {}

    params.each do |key, value|
      if key.match?("^support_module_week_[0-9]_message_[0-9]$")
        messages[key.to_s] = value
        elsif key.match?

      elsif key.match?("^planned_date_")
        planned_dates[key.sub("planned_date_", "")] = value
      elsif key.match?("^planned_hour_")
        planned_hours[key.sub("planned_hour_", "")] = value
      end
    end

    messages.each do |key, value|
      service = ProgramMessageService.new(
        planned_dates[key],
        planned_hours[key],
        recipients,
        value
      ).call
      if service.errors.any?
        redirect_back(fallback_location: root_path, alert: service.errors.join("\n"))
        return
      end
    end
    redirect_back(fallback_location: root_path, notice: "Module programmé")
  end

  # page_action :redirection_targets do
  #   render json: {
  #     results: get_redirection_targets(params[:term])
  #   }
  # end
end
