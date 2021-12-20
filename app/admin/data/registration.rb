ActiveAdmin.register_page "Inscriptions" do

  menu priority: 12, parent: "Rapport"

  content do
    div class: "data-filter" do
      div class: "data-filter-row" do
        div "Naissance"
        input type: "text", class: "datepicker hasDatePicker", style: "margin-right 20px", value: Date.today
        input type: "text", class: "datepicker hasDatePicker", style: "margin-left: 10px", value: Date.today
      end
      div class: "data-filter-row" do
        div "Inscription"
        input type: "text", class: "datepicker hasDatePicker", style: "margin-right 20px", value: Date.today
        input type: "text", class: "datepicker hasDatePicker", style: "margin-left: 10px", value: Date.today
      end
      div class: "data-filter-row" do
        div "Origine d'inscription"
        input type: "text"
      end
      div class: "data-filter-row" do
        div "Tranche d'age"
        input type: "text"
      end
    end
  end
end
