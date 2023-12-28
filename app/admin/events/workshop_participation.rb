ActiveAdmin.register Events::WorkshopParticipation do

  menu parent: "Événements"

  decorate_with Events::WorkshopParticipationDecorator

  has_better_csv
  use_discard

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  includes :related, :workshop

  index do
    selectable_column
    id_column
    column :related do |decorated|
      decorated.related_link
    end
    column :related_current_child do |decorated|
      decorated.related_current_child_link
    end
    column :related_current_child_group
    column :occurred_at
    column :workshop_name
    column :parent_response
    column :display_parent_presence
    actions dropdown: true do |decorated|
      discard_links_args(decorated.model).each do |args|
        item *args
      end
    end
  end

  filter :parent_current_child_group_id_in,
    as: :select,
    collection: proc { child_group_select_collection },
    input_html: {multiple: true, data: {select2: {}}},
    label: "Cohorte"

  filter :comments

  filter :workshop_invitation_response
  filter :workshop_presence

  filter :occurred_at
  filter :created_at

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :related do |model|
        model.related_link
      end
      row :related_current_child do |model|
        model.related_current_child_link
      end
      row :occurred_at
      row :comments, class: "row-pre"
      row :parent_response
      row :display_parent_presence
      row :created_at
      row :discarded_at
    end
  end

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  controller do
    def build_new_resource
      resource = super
      resource.occurred_at = Time.zone.now
      resource
    end
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.input :workshop
    f.inputs do
      if f.object.related
        li class: :input do
          label f.object.class.human_attribute_name("related"), class: :label
          div style: "padding-top: 6px" do
            f.object.decorate.related_link
          end
        end
      end

      f.input :related_type, as: :hidden
      f.input :related_id, as: :hidden

      f.input :occurred_at

      f.input :comments, as: :text, input_html: {rows: 10}

      f.input :parent_response,
              collection: %w[Oui Non], input_html: { data: { select2: {}}}
      f.input :parent_presence,
              collection: workshop_participation_parent_presence,
              input_html: {data: {select2: {}}}
    end
    f.actions
  end

  permit_params :related_type, :related_id, :occurred_at, :comments, :parent_response, :parent_presence, :workshop_id

  # ---------------------------------------------------------------------------
  # CSV EXPORT
  # ---------------------------------------------------------------------------

  csv do
    column :id

    column :related_id
    column :related_name

    column :related_current_child_id
    column :related_current_child_name

    column :related_current_child_group_name
    column :related_current_child_group_status

    column :occurred_at
    column :comments

    column :created_at
    column :updated_at
    column :discarded_at
  end

end
