ActiveAdmin.register_page "Messages" do

  menu false

  content do
    form action: admin_messages_program_module_message_path, method: :post, id: "sms-form" do |f|
      f.input :authenticity_token, type: :hidden, name: :authenticity_token, value: form_authenticity_token
      f.input :parents, type: :hidden, name: :parents, value: params[:parents]
      f.input :tags, type: :hidden, name: :tags, value: params[:tags]
      f.input :groups, type: :hidden, name: :groups, value: params[:groups]

      params[:messages].each do |message|
        div do
          div do
            label (message[0]).to_s
            textarea name: (message[0]).to_s do
              message[1]
            end
            div class: "datetime-container" do
              input type: "text",
                    name: "planned_date_#{message[0]}",
                    class: "datepicker hasDatePicker",
                    style: "margin-right: 20px;",
                    value: params[:planned_date]
              input type: "time",
                    name: "planned_hour_#{message[0]}",
                    value: Time.zone.now.strftime("%H:%M")
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
    p params
    # service = ProgramModuleService.new(
    #   params[:planned_date],
    #   params[:recipients],
    #   params[:module_to_send]
    # ).call
    #
    # if service.errors.any?
    #   redirect_back(fallback_location: root_path, alert: service.errors.join("\n"))
    # else
    #   redirect_back(fallback_location: root_path, notice: "Module programmé")
    # end
  end

end
