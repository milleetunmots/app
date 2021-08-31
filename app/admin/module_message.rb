ActiveAdmin.register_page "Messages" do
  menu false

  content do
    date = params[:planned_date]
    messages = retrieve_messages(params[:module_to_send])

    form action: admin_messages_program_module_message_path, method: :post do |f|
      f.input :authenticity_token, type: :hidden, name: :authenticity_token, value: form_authenticity_token
      f.input :module_to_send, type: :hidden, name: :module_to_send, value: params[:module_to_send]
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
                  f.input "link_#{support_module_week[0]}_#{message[0]}",
                    type: :hidden,
                    name: "link_#{support_module_week[0]}_#{message[0]}",
                    value: message[1][:link]
                  div do
                    small "{URL} disponible dans ce message"
                  end
                end

                div do
                  date = date_update(date)
                  div class: "datetime-container" do
                    input type: "text",
                          name: "planned_date_#{support_module_week[0]}_#{message[0]}",
                          class: "datepicker hasDatePicker",
                          style: "margin-right: 20px;",
                          value: date
                    input type: "time",
                          name: "planned_hour_#{support_module_week[0]}_#{message[0]}",
                          value: Date.strptime(date.to_s, "%Y-%m-%d").saturday? ? "14:00" : "12:30"
                  end
                end
              end
            end
          end
        end
        date = Date.strptime(date.to_s, "%Y-%m-%d")
        date = date.friday? ? date.next_day(3).to_s : date.next_day(2).to_s
      end

      div class: "actions" do
        div class: "action input_action" do
          input type: "submit", value: "Programmer"
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
      if key.match?("^body_support_module_week_[0-9]_message_[0-9]$")
        messages[key.sub("body_", "")] = value
      elsif key.match?("^link_support_module_week_[0-9]_message_[0-9]$")
        links[key.sub("link_", "")] = value
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
        value,
        links[key]
      ).call
      if service.errors.any?
        redirect_back(fallback_location: root_path, alert: service.errors.join("\n"))
        return
      end
    end
    redirect_back(fallback_location: root_path, notice: "Module programmé")
    set_messages_sent(params[:module_to_send])
  end
end
