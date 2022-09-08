ActiveAdmin.register Workshop do

  decorate_with WorkshopDecorator

  has_better_csv
  has_tags
  use_discard

  includes :animator, :participants

  index do
    selectable_column
    id_column
    column :name
    column :topic
    column :animator
    column :co_animator
    column :workshop_date
    column :workshop_address
    column :land_tag
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

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :topic, collection: workshop_topic_select_collection, input_html: {data: {select2: {}}}
      f.input :workshop_date, as: :datepicker
      f.input :animator, input_html: {data: {select2: {}}}
      f.input :co_animator
      address_input f
      f.input :participants, collection: parent_select_collection, input_html: {data: {select2: {}}}
      lands_input(f)
      f.input :invitation_message, input_html: {rows: 5}
    end
    f.actions
  end

  permit_params :topic, :workshop_date, :animator_id, :co_animator, :address, :postal_code, :city_name,
                :invitation_message, tags_params, participant_ids: [], lands_list: []

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
          row :invitation_message
          row :workshop_participants
          row :land_tag
        end
      end
    end
  end
end
