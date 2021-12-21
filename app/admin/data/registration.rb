ActiveAdmin.register_page "Inscriptions" do

  menu priority: 12, parent: "Rapport"

  content do
    div class: "data-year-filter" do
      label "Naissance"
      input type: "text", class: "birthdate-start datepicker hasDatePicker", style: "margin-right 20px", value: Time.now.prev_year.strftime("%Y-%m-%d")
      input type: "text", class: "birthdate-end datepicker hasDatePicker", style: "margin-left: 10px", value: Time.now.strftime("%Y-%m-%d")
    end
    div class: "data-year-filter" do
      label "Inscription"
      input type: "text", class: "registration-date-start datepicker hasDatePicker", style: "margin-right 20px", value: Time.now.prev_year.strftime("%Y-%m-%d")
      input type: "text", class: "registration-date-end datepicker hasDatePicker", style: "margin-left: 10px", value: Time.now.strftime("%Y-%m-%d")
    end
    div class: "data-filter" do
      select multiple: "multiple", id: "registration_sources"
    end
    div class: "data-filter" do
      select multiple: "multiple", id: "age_range"
    end
  end
end
