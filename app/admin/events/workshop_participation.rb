ActiveAdmin.register Events::WorkshopParticipation do

  menu parent: 'Événements'

  decorate_with Events::WorkshopParticipationDecorator

  has_better_csv
  use_discard

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  includes :related

  index do
    selectable_column
    id_column
    column :related do |decorated|
      decorated.related_link
    end
    column :related_first_child do |decorated|
      decorated.related_first_child_link
    end
    column :related_first_child_group
    column :occurred_at
    column :comments do |decorated|
      decorated.truncated_comments
    end
    column :created_at do |decorated|
      l decorated.created_at.to_date, format: :default
    end
    actions do |decorated|
      discard_links(decorated.model, class: 'member_link')
    end
  end

  filter :parent_first_child_group_id_in,
         as: :select,
         collection: proc { child_group_select_collection },
         input_html: { multiple: true, data: { select2: {} } },
         label: 'Cohorte'

  filter :comments

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
      row :related_first_child do |model|
        model.related_first_child_link
      end
      row :occurred_at
      row :comments, class: 'row-pre'
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
      resource.occurred_at = Time.now
      resource
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      if f.object.related
        li class: :input do
          label f.object.class.human_attribute_name('related'), class: :label
          div style: "padding-top: 6px" do
            f.object.decorate.related_link
          end
        end
      end

      f.input :related_type, as: :hidden
      f.input :related_id, as: :hidden

      f.input :occurred_at

      f.input :comments, as: :text, input_html: { rows: 10 }
    end
    f.actions
  end

  permit_params :related_type, :related_id, :occurred_at, :comments

  # ---------------------------------------------------------------------------
  # CSV EXPORT
  # ---------------------------------------------------------------------------

  csv do
    column :id

    column :related_id
    column :related_name

    column :related_first_child_id
    column :related_first_child_name

    column :related_first_child_group_name
    column :related_first_child_has_quit_group

    column :occurred_at
    column :comments

    column :created_at
    column :updated_at
    column :discarded_at
  end

end
