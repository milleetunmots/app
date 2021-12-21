ActiveAdmin.register_page "Inscriptions" do

  menu priority: 12, parent: "Rapport"

  content do
    form action: admin_inscriptions_data_filtered_path, method: :post do |f|
      f.input :authenticity_token, type: :hidden, name: :authenticity_token, value: form_authenticity_token

      div do
        div class: "data-year-filter" do
          label "Naissance"
          input type: "text", name: "birthdate_start", class: "birthdate-start datepicker hasDatePicker", style: "margin-right 20px", value: session[:birthdate_start]
          input type: "text", name: "birthdate_end", class: "birthdate-end datepicker hasDatePicker", style: "margin-left: 10px", value: session[:birthdate_end]
        end
        div class: "data-year-filter" do
          label "Inscription"
          input type: "text", name: "registration_date_start", class: "registration-date-start datepicker hasDatePicker", style: "margin-right 20px", value: session[:registration_date_start]
          input type: "text", name: "registration_date_end", class: "registration-date-end datepicker hasDatePicker", style: "margin-left: 10px", value: session[:registration_date_end]
        end
        div class: "data-filter" do
          select name: "registration_sources[]", multiple: "multiple", id: "registration_sources"
        end
        div class: "data-filter" do
          select name: "age_ranges[]", multiple: "multiple", id: "age_ranges"
        end
        div class: "actions" do
          div class: "action input_action" do
            input type: "submit", value: "Filtrer"
          end
        end
      end

      div do
        render "/admin/data/registration_data"
      end

    end


  end

  page_action :data_filtered, method: :post do
    session[:birthdate_start] = params["birthdate_start"]
    session[:birthdate_end] = params["birthdate_end"]
    session[:registration_date_start] = params["registration_date_start"]
    session[:registration_date_end] = params["registration_date_end"]
    redirect_to admin_inscriptions_path
  end
end
