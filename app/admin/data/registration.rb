ActiveAdmin.register_page "Inscriptions" do
  menu priority: 12, parent: "Rapport"

  content do
    @registration_start = session[:registration_start] ||= Time.now.prev_year.strftime("%Y-%m-%d")
    @registration_end = session[:registration_end] ||= Time.now.strftime("%Y-%m-%d")
    @age_start = session[:age_start] ||= "0 mois"
    @age_end = session[:age_end] ||= "48 mois"
    @registration_sources = session[:registration_sources] ||= nil
    @data_count = data_count(
      @registration_start,
      @registration_end,
      @age_start,
      @age_end,
      @registration_sources
    )

    form action: admin_inscriptions_data_filtered_path, id: "filter-container", method: :post do |f|
      f.input :authenticity_token, type: :hidden, name: :authenticity_token, value: form_authenticity_token

      div do
        div class: "data-filter-row" do
          label "Date"
          input type: "text", name: "registration_start", class: "datepicker hasDatePicker", style: "width: 95%", value: @registration_start
          input type: "text", name: "registration_end", class: "datepicker hasDatePicker", style: "width: 95%", value: @registration_end
        end
        div class: "data-filter-row" do
          label "Ages à l'inscription"
          div do
            select_tag "age_start", options_for_select((0..48).map { |v| "#{v} mois" }, @age_start), data: {select2: {}}, name: "age_start", style: "width: 95%"
          end
          div do
            select_tag "age_end", options_for_select((0..48).map { |v| "#{v} mois" }, @age_end), data: {select2: {}}, style: "width: 95%"
          end
        end
        div class: "data-filter-row" do
          div class: "data-filter-label" do
            label "Origines des inscriptions"
          end
          div class: "data-filter-input" do
            select_tag "registration_sources[]",
              options_for_select(child_registration_source_select_collection, @registration_sources),
              multiple: "multiple", data: {select2: {}},
              style: "width: 100%"
          end
        end
        div class: "actions" do
          div class: "action input_action" do
            input type: "submit", value: "Filtrer"
          end
        end
      end

      div do
        render "/admin/data/registration_data", data_count_values: @data_count
      end
    end
  end

  page_action :data_filtered, method: :post do
    session[:registration_start] = params[:registration_start]
    session[:registration_end] = params[:registration_end]
    session[:age_start] = params[:age_start]
    session[:age_end] = params[:age_end]
    session[:registration_sources] = params[:registration_sources]

    redirect_to admin_inscriptions_path
  end
end
