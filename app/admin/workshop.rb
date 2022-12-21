ActiveAdmin.register Workshop do

  decorate_with WorkshopDecorator

  has_better_csv
  has_tags
  use_discard

  includes :animator, :parents

  index do
    selectable_column
    id_column
    column :name
    column :topic
    column :animator
    column :co_animator
    column :workshop_date
    column :workshop_address
    column :location
    column :workshop_land
    actions dropdown: true do |decorated|
      discard_links_args(decorated.model).each do |args|
        item *args
      end
    end
  end

  filter :name
  filter :animator
  filter :address
  filter :postal_code
  filter :city_name
  filter :location

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :topic, collection: workshop_topic_select_collection, input_html: {data: {select2: {}}}
      f.input :workshop_date, as: :datepicker
      f.input :animator, input_html: {data: {select2: {}}}
      f.input :co_animator
      address_input f
      f.input :location
      f.input :parents, collection: parent_select_collection, input_html: {data: {select2: {}}}
      f.input :workshop_land, collection: Child::LANDS, input_html: {data: {select2: {}}}
      f.input :invitation_message, input_html: {rows: 5}
    end
    f.actions
  end

  permit_params :topic, :workshop_date, :animator_id, :co_animator, :address, :postal_code, :city_name,
                :invitation_message, :workshop_land, :location, tags_params, parent_ids: []

  show do
    tabs do
      tab "Infos" do
        attributes_table do
          row :name
          row :topic
          row :workshop_date
          row :animator
          row :co_animator
          row :workshop_address
          row :location
          row :invitation_message
          row :parents_who_accepted
          row :parents_who_refused
          row :workshop_land
        end
      end
    end
  end

  csv do
    column :id
    column :name
    column :topic
    column :animator_csv
    column :co_animator
    column :workshop_date
    column :workshop_address
    column :location
    column :workshop_land
    column :workshop_participants_csv
    column :parents_who_accepted_csv
    column :parents_who_refused_csv
    column :parents_without_response_csv
  end
end
