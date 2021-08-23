ActiveAdmin.register_page "Messages" do

  menu false

  content do

    form action: admin_messages_program_module_message_path, method: :post, id: "sms-form" do |f|
      f.input :authenticity_token, type: :hidden, name: :authenticity_token, value: form_authenticity_token
      f.input :recipients, type: :hidden, name: :recipients, value: params[:recipients]

      params[:messages].each do |support_module_week|
        div do
          label support_module_week[0]
          support_module_week[1].each do |message|
            div do
              label message[0]
              textarea name: "#{support_module_week[0]}_#{message[0]}" do
                message[1]
              end
              div class: "datetime-container" do
                input type: "text",
                      name: "planned_date_#{support_module_week[0]}_#{message[0]}",
                      class: "datepicker hasDatePicker",
                      style: "margin-right: 20px;",
                      value: params[:planned_date]
                input type: "time",
                      name: "planned_hour_#{support_module_week[0]}_#{message[0]}",
                      value: Time.zone.now.strftime("%H:%M")
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

  page_action :program_module_message, method: :post do

    recipients = params[:recipients].tr('["]', "").delete(" ").split(",")

    messages = {}
    planned_dates = {}
    planned_hours = {}

    params.each do |key, value|
      if key.match?("^support_module_week_[0-9]_message_[0-9]$")
        messages[key.to_s] = value
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
      end
    end
    redirect_back(fallback_location: root_path, notice: "Module programmé")
  end

end
