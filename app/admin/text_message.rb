ActiveAdmin.register Events::TextMessage do

  menu parent: 'Événements'

  decorate_with Events::TextMessageDecorator

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  includes :related

  index do
    selectable_column
    id_column
    column :related do |model|
      model.related_link
    end
    column :related_first_child do |model|
      model.related_first_child_link
    end
    column :occurred_at
    column :body
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    actions
  end

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
      row :body
      row :created_at
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
          label I18n.t('activerecord.attributes.events/text_message.related'), class: :label
          div style: "padding-top: 6px" do
            f.object.decorate.related_link
          end
        end
      end

      f.input :related_type, as: :hidden
      f.input :related_id, as: :hidden

      f.input :occurred_at
      f.input :body, input_html: { rows: 10 }
    end
    f.actions
  end

  permit_params :related_type, :related_id, :occurred_at, :body

  # ---------------------------------------------------------------------------
  # CSV EXPORT
  # ---------------------------------------------------------------------------

  csv do
    column :id

    column :related_id
    column :related_name

    column :related_first_child_id
    column :related_first_child_name

    column :occurred_at
    column :body

    column :created_at
    column :updated_at
  end

end
