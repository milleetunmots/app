ActiveAdmin.register_page "Messages" do
  menu false

  content do
    date = Date.strptime(params[:planned_date].to_s, "%Y-%m-%d")
    messages = retrieve_messages(params[:module_to_send])

    form action: admin_messages_program_module_message_path, method: :post, id: "messages-form" do |f|
      f.input :authenticity_token, type: :hidden, name: :authenticity_token, value: form_authenticity_token
      f.input :module_to_send, type: :hidden, name: :module_to_send, value: params[:module_to_send]
      f.input :recipients, type: :hidden, name: :recipients, value: params[:recipients]

      messages.each_with_index do |support_module_week, week_index|
        next unless support_module_week
        div do
          label "Semaine #{week_index + 1}"
          hr
          columns do
            support_module_week[1].each_with_index do |message, message_index|
              next if message[1][:body].blank?
              column do
                div do
                  label "Message #{message_index + 1}"
                  textarea name: "body_#{support_module_week[0]}_#{message[0]}" do
                    message[1][:body]
                  end
                end
                div id: "message-attachment" do
                  if message[1][:link]
                    f.input RedirectionTarget.find((message[1][:link]).to_i).medium_name,
                      type: :hidden,
                      name: "link_#{support_module_week[0]}_#{message[0]}",
                      value: message[1][:link]
                    div class: "message-variable" do
                      link_to(
                        "Lien: #{RedirectionTarget.find(message[1][:link]).medium_name}",
                        [:admin, RedirectionTarget.find(message[1][:link]).medium],
                        target: "_blank"
                      )
                    end
                  end
                  if message[1][:file]
                    f.input message[1][:file].name,
                      type: :hidden,
                      name: "file_#{support_module_week[0]}_#{message[0]}",
                      value: message[1][:file].spot_hit_id
                    div class: "message-variable" do
                      link_to(
                        "Image: #{Medium.find(message[1][:file].id).name}",
                        admin_media_image_path(message[1][:file].id),
                        target: "_blank"
                      )
                    end
                  end
                end
                div do
                  div class: "datetime-container" do
                    input type: "text",
                          name: "planned_date_#{support_module_week[0]}_#{message[0]}",
                          class: "datepicker hasDatePicker",
                          style: "margin-right: 20px;",
                          value: date
                    input type: "time",
                          name: "planned_hour_#{support_module_week[0]}_#{message[0]}",
                          value: date.saturday? ? "14:00" : "12:30"
                  end
                  date = manage_messages_date(date, support_module_week[1])
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

  page_action :program_module_message, method: :post do
    recipients = params[:recipients].tr('["]', "").delete(" ").split(",")

    messages = {}
    links = {}
    files = {}
    planned_dates = {}
    planned_hours = {}

    params.each do |key, value|
      if key.match?("^body_support_module_week_[0-9]_message_[0-9]$")
        messages[key.sub("body_", "")] = value
      elsif key.match?("^link_support_module_week_[0-9]_message_[0-9]$")
        links[key.sub("link_", "")] = value
      elsif key.match?("^file_support_module_week_[0-9]_message_[0-9]$")
        files[key.sub("file_", "")] = value
      elsif key.match?("^planned_date_")
        planned_dates[key.sub("planned_date_", "")] = value
      elsif key.match?("^planned_hour_")
        planned_hours[key.sub("planned_hour_", "")] = value
      end
    end

    begin
      alert = ""
      messages.each do |key, value|
        if Date.parse(planned_dates[key]).past?
          alert = "Une date antérieure a été choisie"
          raise StandardError, alert
        else
          service = ProgramMessageService.new(
            planned_dates[key],
            planned_hours[key],
            recipients,
            value,
            files[key],
            links[key]
          ).call
          if service.errors.any?
            alert = service.errors.join("\n")
            raise StandardError, alert
          end
        end
      end
    rescue StandardError => e
      redirect_back(fallback_location: root_path, alert: e.message.truncate(200))
    else
      set_messages_sent(params[:module_to_send])
      flash[:notice] = "Module programmé"
      redirect_to admin_support_module_path params[:module_to_send]
    end
  end
end
