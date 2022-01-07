ActiveAdmin.register_page "Cohortes" do
  menu priority: 12, parent: "Rapport"

  content do
    @registration_start = session[:registration_start] ||= Time.now.prev_year.strftime("%Y-%m-%d")
    @registration_end = session[:registration_end] ||= Time.now.strftime("%Y-%m-%d")
    @age_start = session[:age_start] ||= "0 mois"
    @age_end = session[:age_end] ||= "48 mois"
    @groups = session[:groups] ||= nil
    @lands = session[:lands] ||= nil
    @call3_sending_benefits = session[:call3_sending_benefits] ||= nil
    @registration_sources = session[:registration_sources] ||= nil
    @tags = session[:tags] ||= nil

    @data_count = group_data_count(
      @registration_start, @registration_end,
      @age_start, @age_end,
      @groups,
      @lands,
      @call3_sending_benefits,
      @registration_sources,
      @tags
    )

    form action: admin_cohortes_data_filtered_path, class: "filter-container", method: :post do |f|
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
            label "Cohortes"
          end
          div class: "data-filter-input" do
            select_tag "groups[]",
              options_for_select(group_select_collection, @groups),
              multiple: "multiple", data: {select2: {}},
              style: "width: 100%"
          end
        end
        div class: "data-filter-row" do
          div class: "data-filter-label" do
            label "Terrains"
          end
          div class: "data-filter-input" do
            select_tag "lands[]",
              options_for_select(child_land_select_collection, @lands),
              multiple: "multiple", data: {select2: {}},
              style: "width: 100%"
          end
        end
        div class: "data-filter-row" do
          div class: "data-filter-label" do
            label "Apport des envois de l'appel 3"
          end
          div class: "data-filter-input" do
            select_tag "call3_sending_benefits[]",
              options_for_select(child_support_call_sendings_benefits_select_collection, @call3_sending_benefits),
              multiple: "multiple", data: {select2: {}},
              style: "width: 100%"
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
        div class: "data-filter-row" do
          div class: "data-filter-label" do
            label "Tags"
          end
          div class: "data-filter-input" do
            select_tag "tags[]",
              options_for_select(tag_name_collection, @tags),
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
        render "/admin/data/group_data", data_count_values: @data_count
      end
    end
  end

  page_action :data_filtered, method: :post do
    session[:registration_start] = params[:registration_start]
    session[:registration_end] = params[:registration_end]
    session[:age_start] = params[:age_start]
    session[:age_end] = params[:age_end]
    session[:groups] = params[:groups]
    session[:lands] = params[:lands]
    session[:call3_sending_benefits] = params[:call3_sending_benefits]
    session[:tags] = params[:tags]
    session[:registration_sources] = params[:registration_sources]

    redirect_to admin_cohortes_path
  end


end
